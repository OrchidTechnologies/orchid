import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/chat/chat_message.dart';
import 'package:http/http.dart' as http;

/// Core application state that gets auto-saved (excludes messages)
class CoreAppState {
  static const String version = '1.0.0';
  
  final List<Map<String, dynamic>> providers;
  final List<String> selectedModelIds;
  final int? maxTokens;
  final List<String> disabledTools;
  final Map<String, dynamic>? script;
  final Map<String, dynamic> uiPreferences;
  
  CoreAppState({
    required this.providers,
    required this.selectedModelIds,
    this.maxTokens,
    required this.disabledTools,
    this.script,
    required this.uiPreferences,
  });
  
  Map<String, dynamic> toJson() => {
    'version': version,
    'providers': providers,
    'selectedModelIds': selectedModelIds,
    'maxTokens': maxTokens,
    'disabledTools': disabledTools,
    'script': script,
    'uiPreferences': uiPreferences,
  };
  
  factory CoreAppState.fromJson(Map<String, dynamic> json) {
    return CoreAppState(
      providers: List<Map<String, dynamic>>.from(json['providers'] ?? []),
      selectedModelIds: List<String>.from(json['selectedModelIds'] ?? []),
      maxTokens: json['maxTokens'],
      disabledTools: List<String>.from(json['disabledTools'] ?? []),
      script: json['script'],
      uiPreferences: Map<String, dynamic>.from(json['uiPreferences'] ?? {}),
    );
  }
}

/// Full application state including messages (for manual export)
class FullAppState extends CoreAppState {
  final List<Map<String, dynamic>> messages;
  final DateTime exportTime;
  
  FullAppState({
    required super.providers,
    required super.selectedModelIds,
    super.maxTokens,
    required super.disabledTools,
    super.script,
    required super.uiPreferences,
    required this.messages,
    required this.exportTime,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'version': CoreAppState.version,
    'exportTime': exportTime.toIso8601String(),
    'core': super.toJson(),
    'messages': messages,
  };
  
  factory FullAppState.fromJson(Map<String, dynamic> json) {
    final core = CoreAppState.fromJson(json['core'] ?? json);
    return FullAppState(
      providers: core.providers,
      selectedModelIds: core.selectedModelIds,
      maxTokens: core.maxTokens,
      disabledTools: core.disabledTools,
      script: core.script,
      uiPreferences: core.uiPreferences,
      messages: List<Map<String, dynamic>>.from(json['messages'] ?? []),
      exportTime: json['exportTime'] != null 
          ? DateTime.parse(json['exportTime'])
          : DateTime.now(),
    );
  }
}

/// Manages automatic state persistence and manual import/export
class StateManager {
  static const String _storageKey = 'orchid_chat_state';
  static final StateManager _instance = StateManager._internal();
  
  factory StateManager() => _instance;
  StateManager._internal();
  
  bool _autoSaveEnabled = true;
  Timer? _saveDebouncer;
  
  // Callbacks to get current state from various managers
  CoreAppState Function()? _captureStateCallback;
  void Function(CoreAppState)? _applyStateCallback;
  List<ChatMessage> Function()? _getMessagesCallback;
  void Function(List<ChatMessage>)? _setMessagesCallback;
  
  bool get autoSaveEnabled => _autoSaveEnabled;
  
  /// Initialize the state manager with callbacks
  void init({
    required CoreAppState Function() captureState,
    required void Function(CoreAppState) applyState,
    required List<ChatMessage> Function() getMessages,
    required void Function(List<ChatMessage>) setMessages,
  }) {
    _captureStateCallback = captureState;
    _applyStateCallback = applyState;
    _getMessagesCallback = getMessages;
    _setMessagesCallback = setMessages;
    
    // Check for state parameter in URL
    final uri = Uri.base;
    final stateParam = uri.queryParameters['state'];
    
    if (stateParam != null) {
      _autoSaveEnabled = false;
      _loadFromUrl(stateParam);
    } else {
      _loadFromLocalStorage();
    }
  }
  
  /// Called whenever state changes to trigger auto-save
  void onStateChanged() {
    if (!_autoSaveEnabled) return;
    
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), _save);
  }
  
  /// Save current core state to localStorage
  void _save() {
    try {
      if (_captureStateCallback == null) return;
      
      final state = _captureStateCallback!();
      final json = jsonEncode(state.toJson());
      html.window.localStorage[_storageKey] = json;
      log('State auto-saved (${json.length} bytes)');
    } catch (e) {
      log('Failed to auto-save state: $e');
    }
  }
  
  /// Load state from localStorage
  void _loadFromLocalStorage() {
    try {
      final saved = html.window.localStorage[_storageKey];
      if (saved != null && _applyStateCallback != null) {
        final json = jsonDecode(saved);
        final state = CoreAppState.fromJson(json);
        _applyStateCallback!(state);
        log('State loaded from localStorage');
      }
    } catch (e) {
      log('Failed to load saved state: $e');
    }
  }
  
  /// Load state from a URL
  Future<void> _loadFromUrl(String url) async {
    try {
      log('Loading state from URL: $url');
      
      String stateData;
      
      // Handle data URLs
      if (url.startsWith('data:')) {
        final base64Part = url.split(',').last;
        final bytes = base64Decode(base64Part);
        stateData = utf8.decode(bytes);
      } else {
        // Fetch from URL
        final response = await http.get(Uri.parse(url));
        stateData = response.body;
      }
      
      await importStateJson(stateData, isFullState: true);
      log('State loaded from URL');
    } catch (e) {
      log('Failed to load state from URL: $e');
    }
  }
  
  /// Export full state including messages
  Future<String> exportFullState() async {
    if (_captureStateCallback == null || _getMessagesCallback == null) {
      throw Exception('State manager not initialized');
    }
    
    final coreState = _captureStateCallback!();
    final messages = _getMessagesCallback!();
    
    final fullState = FullAppState(
      providers: coreState.providers,
      selectedModelIds: coreState.selectedModelIds,
      maxTokens: coreState.maxTokens,
      disabledTools: coreState.disabledTools,
      script: coreState.script,
      uiPreferences: coreState.uiPreferences,
      messages: messages.map((m) => m.toJson()).toList(),
      exportTime: DateTime.now(),
    );
    
    return const JsonEncoder.withIndent('  ').convert(fullState.toJson());
  }
  
  /// Import state from JSON string
  Future<void> importStateJson(String stateJson, {bool isFullState = false}) async {
    if (_applyStateCallback == null) {
      throw Exception('State manager not initialized');
    }
    
    final json = jsonDecode(stateJson);
    
    if (isFullState && json['messages'] != null) {
      // Full state with messages
      final fullState = FullAppState.fromJson(json);
      
      // Apply core state
      _applyStateCallback!(fullState);
      
      // Restore messages if callback is available
      if (_setMessagesCallback != null && fullState.messages.isNotEmpty) {
        final messages = fullState.messages
            .map((m) => ChatMessage.fromJson(m))
            .toList();
        _setMessagesCallback!(messages);
      }
    } else {
      // Core state only
      final coreState = CoreAppState.fromJson(json);
      _applyStateCallback!(coreState);
    }
    
    // Re-enable auto-save after manual import
    _autoSaveEnabled = true;
    onStateChanged(); // Save the imported state
  }
  
  /// Clear all saved state
  void clearState() {
    html.window.localStorage.remove(_storageKey);
    log('Cleared saved state');
  }
  
  /// Get a shareable URL with current state
  Future<String> getShareableUrl() async {
    final state = await exportFullState();
    final base64 = base64Encode(utf8.encode(state));
    final dataUrl = 'data:application/json;base64,$base64';
    
    final baseUrl = html.window.location.origin + (html.window.location.pathname ?? '');
    return '$baseUrl?state=${Uri.encodeComponent(dataUrl)}';
  }
}