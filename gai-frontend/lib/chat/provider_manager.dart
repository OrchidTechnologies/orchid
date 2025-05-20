import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log.dart';  // Import logWrapped
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_message.dart';
import 'model_manager.dart';
import 'provider_connection.dart';
import 'tool_definition.dart';
import 'dart:convert';
import 'dart:math' as math;

// Provider connection state
class ProviderState {
  final String id;
  final String name;
  final String wsUrl;
  final String httpUrl;
  ProviderConnection? connection;
  bool connected = false;
  List<ToolDefinition> availableTools = [];
  
  // Runtime capability detection
  bool get supportsInference => connection?.inferenceClient != null;
  
  // A provider supports tools if it has any available tools AND is connected
  bool get supportsTools => connected && availableTools.isNotEmpty;
  
  // Determine if this is a tools-only provider (has tools but no inference capability)
  bool get isToolsOnlyProvider => supportsTools && !supportsInference;
  
  ProviderState({
    required this.id,
    required this.name,
    required this.wsUrl,
    required this.httpUrl,
    this.connection,
  });
}

// Manage the provider state for the UI, including the map of providers and the active provider connection.
class ProviderManager {
  // Singleton instance
  static ProviderManager? _instance;
  static ProviderManager get instance {
    if (_instance == null) {
      throw Exception('ProviderManager must be initialized before accessing instance');
    }
    return _instance!;
  }
  
  // Configuration for all providers
  late final Map<String, Map<String, dynamic>> _providersConfig;
  
  // Active providers with their connection state
  final Map<String, ProviderState> _providerStates = {};
  
  // Currently selected inference provider ID
  String? _activeInferenceProviderId;
  
  // Callbacks
  final VoidCallback onProviderConnected;
  final VoidCallback onProviderDisconnected;
  final void Function(ChatMessage) onChatMessage;

  // Tool management
  final ValueNotifier<List<ToolDefinition>> availableToolsNotifier = ValueNotifier<List<ToolDefinition>>([]);
  Set<String> _disabledTools = {};
  
  final ModelManager modelsState;
  AccountDetail? accountDetail;
  
  // Get active inference provider connection (backward compatibility)
  ProviderConnection? get providerConnection => 
      _activeInferenceProviderId != null 
          ? _providerStates[_activeInferenceProviderId]?.connection 
          : null;

  // Get all providers
  List<ProviderState> get allProviders => 
      _providerStates.values.toList();
      
  // Get all connected providers
  List<ProviderState> get connectedProviders => 
      _providerStates.values.where((p) => p.connected).toList();
  
  // Get all connected providers that support tools
  List<ProviderState> get toolProviders => 
      _providerStates.values.where((p) => p.connected && p.supportsTools).toList();
      
  // Flag to track if there are active requests that can be cancelled
  bool _hasCancellableRequests = false;
  
  // Update active request state - also used by Chat widget to track request state
  void setHasCancellableRequests(bool hasRequests) {
    _hasCancellableRequests = hasRequests;
  }
  
  // Check if any active requests are in progress
  bool get hasCancellableRequests => _hasCancellableRequests;
  
  // Cancel active requests
  void cancelActiveRequests() {
    log('ProviderManager: Cancelling all active requests');
    
    // Debug log all providers
    for (var provider in allProviders) {
      log('Provider ${provider.name}: connected=${provider.connected}, inference=${provider.supportsInference}, supports tools=${provider.supportsTools}');
    }
    
    // First cancel any active inference requests
    if (_activeInferenceProviderId != null) {
      final activeProvider = _providerStates[_activeInferenceProviderId];
      if (activeProvider != null && activeProvider.connected) {
        log('Cancelling requests on active inference provider: ${activeProvider.name}');
        if (activeProvider.connection != null) {
          activeProvider.connection!.cancelRequests();
        } else {
          log('WARNING: No connection object for active provider ${activeProvider.name}');
        }
      } else {
        log('Active provider not found or not connected: $_activeInferenceProviderId');
      }
    } else {
      log('No active inference provider set');
    }
    
    // Then cancel any pending tool requests on all providers
    int cancelCount = 0;
    for (final provider in toolProviders) {
      log('Cancelling tool requests on provider: ${provider.name}');
      if (provider.connection != null) {
        provider.connection!.cancelRequests();
        cancelCount++;
      } else {
        log('WARNING: No connection object for tool provider ${provider.name}');
      }
    }
    
    // Extra cancellation for any tool-only providers that might not be included in toolProviders
    for (final provider in allProviders) {
      if (provider.isToolsOnlyProvider && !toolProviders.contains(provider)) {
        if (provider.connection != null) {
          log('Cancelling requests on tool-only provider: ${provider.name} (not in regular toolProviders list)');
          provider.connection!.cancelRequests();
          cancelCount++;
        }
      }
    }
    
    // Add a summary of what was cancelled
    log('Cancelled requests on $cancelCount tool providers');
    
    // Mark all requests as cancelled
    setHasCancellableRequests(false);
    
    // Don't send a system message from here - already handled by the chat UI
    // This prevents duplicate cancel messages
  }

  // Check if we have an active inference provider connection
  bool get connected => _activeInferenceProviderId != null && 
      _providerStates[_activeInferenceProviderId]?.connected == true;
  
  // Check if we have an inference client for the active provider
  bool get hasProviderConnection => providerConnection != null;
  bool get hasInferenceClient {
    // Check if we have an active provider with inference
    if (_activeInferenceProviderId != null && 
        _providerStates[_activeInferenceProviderId]?.connected == true &&
        _providerStates[_activeInferenceProviderId]?.connection?.inferenceClient != null) {
      return true;
    }
    
    // If no active provider is set but we have inference-capable providers,
    // try to auto-select the first one
    if (_activeInferenceProviderId == null) {
      for (final state in _providerStates.values) {
        if (state.connected && state.supportsInference) {
          log('Auto-selecting inference provider: ${state.name}');
          _activeInferenceProviderId = state.id;
          return true;
        }
      }
    }
    
    return false;
  }

  ProviderManager({
    required this.modelsState,
    required this.onProviderConnected,
    required this.onProviderDisconnected,
    required this.onChatMessage,
  }) {
    _instance = this;
    init();
  }

  // Helper method to normalize URLs for comparison (removes protocol)
  String _normalizeUrlForComparison(String url) {
    // Strip protocol
    if (url.startsWith('http://')) {
      return url.substring(7);
    } else if (url.startsWith('https://')) {
      return url.substring(8);
    } else if (url.startsWith('ws://')) {
      return url.substring(5);
    } else if (url.startsWith('wss://')) {
      return url.substring(6);
    }
    return url;
  }
  
  // Helper to determine if a URL uses secure protocol
  bool _isSecureProtocol(String url) {
    return url.startsWith('https://') || url.startsWith('wss://');
  }
  
  // Deduplicate providers by URL, preferring secure connections
  Map<String, Map<String, dynamic>> _deduplicateProviders(Map<String, Map<String, dynamic>> providers) {
    // Map normalized URLs to provider entries
    final normalizedUrlMap = <String, Map<String, dynamic>>{};
    
    // First pass: collect all providers by normalized URL
    for (final entry in providers.entries) {
      final id = entry.key;
      final config = entry.value;
      final url = config['url'] ?? '';
      
      if (url.isEmpty) continue;
      
      final normalizedUrl = _normalizeUrlForComparison(url);
      
      // If we haven't seen this URL before, add it
      if (!normalizedUrlMap.containsKey(normalizedUrl)) {
        normalizedUrlMap[normalizedUrl] = {
          'id': id,
          'config': config,
          'isSecure': _isSecureProtocol(url),
        };
      } else {
        // If we have seen this URL before, prefer secure connection
        final existing = normalizedUrlMap[normalizedUrl]!;
        final existingIsSecure = existing['isSecure'] as bool;
        
        // If current provider is secure and existing is not, replace
        if (_isSecureProtocol(url) && !existingIsSecure) {
          normalizedUrlMap[normalizedUrl] = {
            'id': id,
            'config': config,
            'isSecure': true,
          };
          log('Preferring secure provider: $url over previous non-secure version');
        } else {
          log('Skipping duplicate provider: $url (keeping ${existing['config']['url']})');
        }
      }
    }
    
    // Build deduplicated provider map
    final dedupedProviders = <String, Map<String, dynamic>>{};
    for (final entry in normalizedUrlMap.entries) {
      final providerInfo = entry.value;
      dedupedProviders[providerInfo['id']] = providerInfo['config'];
    }
    
    log('Deduplicated ${providers.length} providers to ${dedupedProviders.length}');
    return dedupedProviders;
  }

  void init() {
    // 1. Get providers from different sources
    final envProviders = getFromEnv();
    final urlProviders = getFromUrlParams();
    
    // 2. Combine and deduplicate providers
    final combinedProviders = {...envProviders};
    combinedProviders.addAll(urlProviders);
    
    // Deduplicate the providers
    _providersConfig = _deduplicateProviders(combinedProviders);
    
    log('Initialized with ${_providersConfig.length} providers from env/URL after deduplication');
    
    // 3. Load saved tool and provider preferences - these will add saved providers
    Future.delayed(const Duration(milliseconds: 300), () async {
      await _loadToolPreferences();
      await _loadProviderConfigs();
      
      // Initialize provider states for any providers from environment/URL
      for (var entry in _providersConfig.entries) {
        final id = entry.key;
        final config = entry.value;
        
        // Skip if already in provider states
        if (_providerStates.containsKey(id)) continue;
        
        // Create provider state
        final url = config['url'] ?? '';
        final name = config['name'] ?? 'Provider';
        
        // Convert WebSocket URL to HTTP URL
        String httpUrl;
        if (url.startsWith('ws://')) {
          httpUrl = 'http://' + url.substring(5);
        } else if (url.startsWith('wss://')) {
          httpUrl = 'https://' + url.substring(6);
        } else {
          // If it's not a WebSocket URL, use as-is
          httpUrl = url;
        }
        
        _providerStates[id] = ProviderState(
          id: id,
          name: name,
          wsUrl: url,
          httpUrl: httpUrl,
        );
      }
      
      // Save provider configurations after adding environment/URL providers
      _saveProviderConfigs();
    });
    
    // 4. Attempt to connect to any configured tool providers in the background
    Future.delayed(const Duration(milliseconds: 500), () {
      if (accountDetail != null) {
        connectToAllToolProviders().then((_) {
          if (getAllAvailableTools().isNotEmpty) {
            log('Found ${getAllAvailableTools().length} tools across ${toolProviders.length} providers');
            // Update the tools notifier
            availableToolsNotifier.value = getAllAvailableTools();
          }
        });
      }
    });
  }

  void setAccountDetail(AccountDetail? accountDetail) {
    this.accountDetail = accountDetail;
    
    // Disconnect all providers when account changes
    for (final providerId in _providerStates.keys) {
      final state = _providerStates[providerId];
      if (state?.connected == true) {
        state?.connection?.dispose();
        state?.connected = false;
      }
    }
    
    // Clear active provider
    _activeInferenceProviderId = null;
    
    // If account is set, attempt to connect to providers
    if (accountDetail != null) {
      // Connect to tool providers in the background
      Future.delayed(const Duration(milliseconds: 500), () {
        connectToAllToolProviders().then((_) {
          if (getAllAvailableTools().isNotEmpty) {
            log('Connected to tool providers: found ${getAllAvailableTools().length} tools');
            // Update the tools notifier
            availableToolsNotifier.value = getAllAvailableTools();
          }
        });
      });
    }
  }

  void setProviders(Map<String, Map<String, dynamic>> providers) {
    _providersConfig = providers;
  }

  void setUserProvider(String provider) {
    setProviders({
      'user-provider': {'url': provider, 'name': 'User Provider'}
    });
  }
  
  // Process providers from a URL query parameter
  void addProvidersFromUrlParam(String queryParam) {
    if (queryParam.isEmpty) return;
    
    try {
      // Format is name1:url1,name2:url2
      final providerPairs = queryParam.split(',');
      for (final pair in providerPairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final name = parts[0];
          final url = parts[1];
          
          // Add this provider
          addToolProvider(url, name);
          log('Added provider from URL query param: $name, $url');
        }
      }
    } catch (e) {
      log('Error processing providers from URL param: $e');
    }
  }

  // Add a new provider
  void addToolProvider(String url, String name) {
    // First check if this URL already exists (ignoring protocol)
    final normalizedNewUrl = _normalizeUrlForComparison(url);
    String? existingProviderId;
    bool shouldReplace = false;
    
    // Check for duplicates
    for (final entry in _providersConfig.entries) {
      final existingUrl = entry.value['url'] ?? '';
      if (existingUrl.isEmpty) continue;
      
      final normalizedExistingUrl = _normalizeUrlForComparison(existingUrl);
      if (normalizedExistingUrl == normalizedNewUrl) {
        existingProviderId = entry.key;
        
        // If new URL is secure and existing is not, replace it
        if (_isSecureProtocol(url) && !_isSecureProtocol(existingUrl)) {
          shouldReplace = true;
          log('Replacing non-secure provider ${existingUrl} with secure version ${url}');
        } else {
          log('Provider with this URL already exists (ignoring protocol): ${existingUrl}');
          // If we already have this provider (and it's not less secure), just return
          if (!shouldReplace) return;
        }
        
        break;
      }
    }
    
    // Generate a new ID or reuse existing one
    final id = existingProviderId ?? 'provider-${DateTime.now().millisecondsSinceEpoch}';
    final provider = {
      'url': url,
      'name': name,
    };
    
    // Add or replace in config
    _providersConfig[id] = provider;
    
    // Create provider state - convert WebSocket URL to HTTP URL
    String httpUrl;
    if (url.startsWith('ws://')) {
      httpUrl = 'http://' + url.substring(5);
    } else if (url.startsWith('wss://')) {
      httpUrl = 'https://' + url.substring(6);
    } else {
      // If it's not a WebSocket URL, use as-is
      httpUrl = url;
    }
    
    // If replacing, disconnect existing provider first
    if (existingProviderId != null && _providerStates.containsKey(existingProviderId)) {
      final existingState = _providerStates[existingProviderId];
      if (existingState?.connected == true) {
        existingState?.connection?.dispose();
      }
    }
    
    // Create or update provider state
    _providerStates[id] = ProviderState(
      id: id,
      name: name,
      wsUrl: url,
      httpUrl: httpUrl,
    );
    
    // Save provider configuration
    _saveProviderConfigs();
    
    // Try to connect to this provider if we have account details
    if (accountDetail != null) {
      _connectProvider(id);
    }
  }
  
  // Remove a provider by ID
  void removeProvider(String providerId) {
    // Disconnect if connected
    final state = _providerStates[providerId];
    if (state?.connected == true) {
      state?.connection?.dispose();
    }
    
    // Remove from configurations
    _providersConfig.remove(providerId);
    _providerStates.remove(providerId);
    
    // If we removed the active inference provider, clear it
    if (_activeInferenceProviderId == providerId) {
      _activeInferenceProviderId = null;
    }
    
    // Clear the models for this provider
    modelsState.clearProviderModels(providerId);
    
    // Save provider configuration
    _saveProviderConfigs();
    
    // Update available tools
    availableToolsNotifier.value = getAllAvailableTools();
  }
  
  // Save provider configurations to persistent storage
  Future<void> _saveProviderConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert provider configs to JSON
      final providers = _providersConfig.entries.map((e) => {
        'id': e.key,
        'url': e.value['url'],
        'name': e.value['name'] ?? 'Provider',
      }).toList();
      
      // Save as JSON string
      await prefs.setString('tool_providers', jsonEncode(providers));
      log('Saved ${providers.length} provider configurations');
    } catch (e) {
      log('Error saving provider configurations: $e');
    }
  }
  
  // Load provider configurations from persistent storage
  Future<void> _loadProviderConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final providersJson = prefs.getString('tool_providers');
      
      if (providersJson != null && providersJson.isNotEmpty) {
        try {
          final List<dynamic> providersFromJson = jsonDecode(providersJson);
          log('Loading ${providersFromJson.length} saved providers');
          
          // Collect providers from JSON into a temporary map
          final Map<String, Map<String, dynamic>> loadedProviders = {};
          for (var provider in providersFromJson) {
            final id = provider['id'] as String;
            final url = provider['url'] as String;
            final name = provider['name'] as String? ?? 'Provider';
            
            // Add to temporary map
            loadedProviders[id] = {
              'url': url,
              'name': name,
            };
          }
          
          // Deduplicate loaded providers
          final dedupedProviders = _deduplicateProviders(loadedProviders);
          
          // Merge with existing providers, deduplicating again
          final mergedProviders = {..._providersConfig};
          mergedProviders.addAll(dedupedProviders);
          _providersConfig = _deduplicateProviders(mergedProviders);
          
          log('After deduplication and merging: ${_providersConfig.length} providers');
          
          // Create provider states for each provider
          for (var entry in _providersConfig.entries) {
            final id = entry.key;
            final config = entry.value;
            
            // Skip if already in provider states
            if (_providerStates.containsKey(id)) continue;
            
            final url = config['url'] ?? '';
            final name = config['name'] ?? 'Provider';
            
            // Create provider state
            String httpUrl;
            if (url.startsWith('ws://')) {
              httpUrl = 'http://' + url.substring(5);
            } else if (url.startsWith('wss://')) {
              httpUrl = 'https://' + url.substring(6);
            } else {
              httpUrl = url;
            }
            
            _providerStates[id] = ProviderState(
              id: id,
              name: name,
              wsUrl: url,
              httpUrl: httpUrl,
            );
          }
        } catch (e) {
          log('Error parsing saved providers: $e');
        }
      }
    } catch (e) {
      log('Error loading provider configurations: $e');
    }
  }
  
  // Get all available tools across all connected providers
  List<ToolDefinition> getAllAvailableTools() {
    final tools = <ToolDefinition>[];
    
    for (final providerId in _providerStates.keys) {
      final state = _providerStates[providerId];
      if (state?.connected == true) {
        tools.addAll(state!.availableTools);
      }
    }
    
    return tools;
  }
  
  // Get only enabled tools
  List<ToolDefinition> getEnabledTools() {
    return getAllAvailableTools()
        .where((tool) => !_disabledTools.contains(tool.name))
        .toList();
  }
  
  // Tool enabling/disabling methods
  void enableTool(String toolName) {
    _disabledTools.remove(toolName);
    _saveToolPreferences();
  }

  void disableTool(String toolName) {
    _disabledTools.add(toolName);
    _saveToolPreferences();
  }

  void enableAllTools() {
    _disabledTools.clear();
    _saveToolPreferences();
  }

  void disableAllTools() {
    _disabledTools.addAll(getAllAvailableTools().map((tool) => tool.name));
    _saveToolPreferences();
  }
  
  bool isToolEnabled(String toolName) {
    return !_disabledTools.contains(toolName);
  }
  
  // Find provider ID for a given connection
  String? findProviderIdForConnection(ProviderConnection connection) {
    for (final entry in _providerStates.entries) {
      if (entry.value.connection == connection) {
        return entry.key;
      }
    }
    return null;
  }
  
  // Update a provider's tools and notify the UI
  void updateProviderTools(String providerId, List<ToolDefinition> tools) {
    final state = _providerStates[providerId];
    if (state != null) {
      // Make defensive copy to ensure we're not sharing mutable lists
      state.availableTools = List.from(tools);
      log('Updated provider $providerId with ${tools.length} tools');
      
      // Enable new tools by default
      for (var tool in tools) {
        // Only enable if not explicitly disabled before
        if (!_disabledTools.contains(tool.name)) {
          log('Enabling new tool by default: ${tool.name}');
          // No need to call enableTool since not being in _disabledTools
          // means it's already enabled
        }
      }
      
      // Create a new list to trigger the ValueNotifier change detection
      final allTools = getAllAvailableTools();
      
      // Log the tool names and enabled status
      log('All available tools: ${allTools.map((t) => '${t.name} (${isToolEnabled(t.name) ? "enabled" : "disabled"})').join(', ')}');
      
      // Create a fresh list for the notifier (to trigger change detection)
      availableToolsNotifier.value = List.from(allTools);
      
      // Also explicitly notify listeners to ensure updates
      // This is necessary because sometimes just changing the value isn't detected
      Future.microtask(() {
        availableToolsNotifier.notifyListeners();
      });
    }
  }
  
  // Save and load tool preferences
  Future<void> _saveToolPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('disabled_tools', _disabledTools.toList());
      
      // Notify UI that tool preferences have changed
      availableToolsNotifier.value = [...getAllAvailableTools()];
      availableToolsNotifier.notifyListeners();
    } catch (e) {
      log('Error saving tool preferences: $e');
    }
  }
  
  Future<void> _loadToolPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final disabledTools = prefs.getStringList('disabled_tools');
      if (disabledTools != null) {
        _disabledTools = disabledTools.toSet();
      }
    } catch (e) {
      log('Error loading tool preferences: $e');
    }
  }
  
  // Find which provider offers a specific tool
  ProviderState? getToolProvider(String toolName) {
    // Removed verbose logging that was causing log spam
    // log('Looking for provider for tool: $toolName');
    
    // Only output detailed logs if specifically requested for debugging
    bool _debugToolRouting = false; // Set to true only when debugging tool routing
    
    if (_debugToolRouting) {
      // Log all providers and their tools (only when debugging)
      for (final providerId in _providerStates.keys) {
        final state = _providerStates[providerId];
        if (state?.connected == true) {
          final toolNames = state!.availableTools.map((t) => t.name).join(', ');
          log('Provider ${state.name} (${state.id}) has tools: $toolNames');
          log('  - supportsInference: ${state.supportsInference}, supportsTools: ${state.supportsTools}, isToolsOnlyProvider: ${state.isToolsOnlyProvider}');
        }
      }
    }
    
    // First: Check for explicitly disabled tools - don't try to find a provider for disabled tools
    if (_disabledTools.contains(toolName)) {
      log('Tool $toolName is explicitly disabled, no provider will be found');
      return null;
    }
    
    // Second pass: Look for exact matches across all connected providers
    List<ProviderState> matchingProviders = [];
    ProviderState? toolsOnlyMatch = null;
    
    for (final providerId in _providerStates.keys) {
      final state = _providerStates[providerId];
      if (state?.connected == true) {
        // Look for exact name match
        final hasExactMatch = state!.availableTools
            .any((tool) => tool.name == toolName);
        
        if (hasExactMatch) {
          // Reduce log noise
          // log('Found tool $toolName in provider ${state.name}');
          matchingProviders.add(state);
          
          // Keep track of any tools-only provider with an exact match
          // We'll prioritize these later
          if (state.isToolsOnlyProvider) {
            toolsOnlyMatch = state;
            // Reduce log noise
            // log('Provider ${state.name} is a tools-only provider with exact match for $toolName');
          }
        }
      }
    }
    
    // If we have a tools-only provider with this tool, prioritize it above all others
    if (toolsOnlyMatch != null) {
      // Reduce log noise
      // log('Prioritizing tools-only provider ${toolsOnlyMatch.name} for tool $toolName');
      return toolsOnlyMatch;
    }
    
    // If we found exactly one provider with this tool, return it
    if (matchingProviders.length == 1) {
      // Reduce log noise
      // log('Only one provider (${matchingProviders.first.name}) has tool $toolName');
      return matchingProviders.first;
    }
    
    // If we found multiple providers with this tool (but none is tools-only), 
    // use heuristics to select the best one
    if (matchingProviders.length > 1) {
      // Reduce log noise
      // log('Found multiple providers (${matchingProviders.length}) with tool $toolName, selecting best match');
      
      // Sort by provider name containing part of the tool name (suggesting specialization)
      // This helps match tools with their intended providers when multiple providers offer the same tool
      final toolNameParts = toolName.split('_');
      for (final part in toolNameParts) {
        if (part.length > 2) { // Only consider meaningful parts
          for (final provider in matchingProviders) {
            if (provider.name.toLowerCase().contains(part.toLowerCase())) {
              // Reduce log noise
              // log('Selected provider ${provider.name} for tool $toolName based on name matching');
              return provider;
            }
          }
        }
      }
      
      // Last resort: Just pick the first one
      // Reduce log noise
      // log('Selected first matching provider ${matchingProviders.first.name} for tool $toolName (default selection)');
      return matchingProviders.first;
    }
    
    // If exact match wasn't found, try case-insensitive matching as fallback
    // This helps with tools that might have case differences
    matchingProviders = [];
    
    for (final providerId in _providerStates.keys) {
      final state = _providerStates[providerId];
      if (state?.connected == true) {
        final hasMatch = state!.availableTools
            .any((tool) => tool.name.toLowerCase() == toolName.toLowerCase());
        
        if (hasMatch) {
          log('Found tool $toolName (case-insensitive) in provider ${state.name}');
          matchingProviders.add(state);
          
          // Prioritize tools-only providers even for case-insensitive matches
          if (state.isToolsOnlyProvider) {
            log('Selected tools-only provider ${state.name} for tool $toolName (case-insensitive)');
            return state;
          }
        }
      }
    }
    
    // Apply the same selection logic as above for case-insensitive matches
    if (matchingProviders.length == 1) {
      return matchingProviders.first;
    } else if (matchingProviders.length > 1) {
      return matchingProviders.first; // Just pick the first one
    }
    
    log('No provider found for tool: $toolName');
    return null;
  }

  // Connect to the initial provider
  void connectToInitialProvider() {
    if (_providersConfig.isEmpty) {
      log('No providers configured');
      return;
    }

    // Get first provider from the list
    final firstProviderId = _providersConfig.keys.first;
    final firstProvider = _providersConfig[firstProviderId];
    if (firstProvider == null) {
      log('Invalid provider configuration');
      return;
    }

    log('Connecting to initial provider: ${firstProvider['name']}');
    _connectProvider(firstProviderId);
  }

  // Connect to all configured providers
  Future<void> connectToAllToolProviders() async {
    if (_providersConfig.isEmpty) {
      log('No providers configured');
      return;
    }
    
    log('Connecting to all available providers...');
    int successCount = 0;
    int toolProvidersCount = 0;
    
    // Connect to each provider
    for (final providerId in _providersConfig.keys) {
      final providerConfig = _providersConfig[providerId];
      if (providerConfig == null) {
        log('Provider config is null for $providerId');
        continue;
      }
      
      // Skip if already connected
      if (_providerStates[providerId]?.connected == true) {
        log('Provider $providerId already connected');
        successCount++;
        // Check if it supports tools
        if (_providerStates[providerId]?.supportsTools == true) {
          toolProvidersCount++;
        }
        continue;
      }
      
      // Check URL is valid
      final url = providerConfig['url'];
      if (url == null || url.isEmpty) {
        log('Invalid URL for provider $providerId');
        continue;
      }
      
      log('Attempting to connect to provider $providerId (${providerConfig['name']})');
      
      // Connect to this provider
      final success = await _connectProvider(providerId);
      if (success) {
        successCount++;
        
        // Check if it's a tool provider after connection
        if (_providerStates[providerId]?.supportsTools == true) {
          toolProvidersCount++;
          log('Provider $providerId supports tools');
        }
        
        // If this is a tools-only provider (no inference capability),
        // make sure we update our notifier so UI components know tools are available
        final state = _providerStates[providerId];
        if (state?.supportsTools == true && state?.supportsInference == false) {
          log('Provider $providerId is a tools-only provider');
          // Make sure tools are reflected in the UI
          availableToolsNotifier.value = getAllAvailableTools();
        }
      }
      
      // Note: Tools and models are fetched in the callbacks
    }
    
    log('Finished connecting to providers. Connected to $successCount providers ($toolProvidersCount with tools)');
  }

  void _addMessage(
    ChatMessageSource source,
    String message, {
    Map<String, dynamic>? metadata,
    String sourceName = '',
    String? modelId,
    String? modelName,
  }) {
    final chatMessage = ChatMessage(
      source: source,
      message: message,
      metadata: metadata,
      sourceName: sourceName,
      modelId: modelId,
      modelName: modelName,
    );
    onChatMessage(chatMessage);
  }

  // Connect with a direct auth token (for inference)
  void connectWithAuthToken(String token, String inferenceUrl) async {
    final providerId = 'direct-auth';
    
    // Clean up existing connection for this provider if any
    final existingState = _providerStates[providerId];
    if (existingState?.connected == true) {
      existingState?.connection?.dispose();
      existingState?.connected = false;
    }

    try {
      final connection = await ProviderConnection.connect(
        billingUrl: inferenceUrl,
        inferenceUrl: inferenceUrl,
        contract: null,
        accountDetail: null,
        authToken: token,
        onMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
        onConnect: () {
          _providerConnected(providerId, 'Direct Auth');
        },
        onDisconnect: () {
          _providerDisconnected(providerId);
        },
        onError: (msg) {
          _addMessage(ChatMessageSource.system, 'Provider error: $msg');
        },
        onSystemMessage: (msg) {
          _addMessage(ChatMessageSource.system, msg);
        },
        onInternalMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
      );
      
      // Create or update provider state
      final state = ProviderState(
        id: providerId,
        name: 'Direct Auth',
        wsUrl: inferenceUrl,
        httpUrl: inferenceUrl,
        connection: connection,
      );
      _providerStates[providerId] = state;
      
      // Set as active inference provider
      _activeInferenceProviderId = providerId;
      
      // Fetch models after connection
      if (connection.inferenceClient != null) {
        await modelsState.fetchModelsForProvider(
          providerId,
          connection.inferenceClient!,
        );
      }
    } catch (e, stack) {
      log('Error connecting with auth token: $e\n$stack');
      _addMessage(ChatMessageSource.system, 'Failed to connect: $e');
    }
  }

  // Connect to a specific provider
  Future<bool> _connectProvider(String providerId) async {
    var account = accountDetail;
    if (account == null) {
      log('_connectProvider() -- No account');
      return false;
    }
    if (_providersConfig.isEmpty) {
      log('_connectProvider() -- _providersConfig.isEmpty');
      return false;
    }

    final providerInfo = _providersConfig[providerId];
    if (providerInfo == null) {
      log('Provider not found: $providerId');
      return false;
    }

    final wsUrl = providerInfo['url'] ?? '';
    final name = providerInfo['name'] ?? '';
    
    // Convert WebSocket URL to HTTP URL while preserving path
    String httpUrl;
    if (wsUrl.startsWith('ws://')) {
      httpUrl = 'http://' + wsUrl.substring(5);
    } else if (wsUrl.startsWith('wss://')) {
      httpUrl = 'https://' + wsUrl.substring(6);
    } else {
      // If it's not a WebSocket URL, use as-is (likely already HTTP/HTTPS)
      httpUrl = wsUrl;
    }

    log('Connecting to provider: $name (ws: $wsUrl, http: $httpUrl)');
    
    // Clean up existing connection for this provider if any
    final existingState = _providerStates[providerId];
    if (existingState?.connected == true) {
      existingState?.connection?.dispose();
      existingState?.connected = false;
    }

    try {
      final connection = await ProviderConnection.connect(
        billingUrl: wsUrl,
        inferenceUrl: httpUrl,
        contract:
            EthereumAddress.from('0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'),
        accountDetail: account,
        onMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
        onConnect: () {
          _providerConnected(providerId, name);
        },
        onDisconnect: () {
          _providerDisconnected(providerId);
        },
        onError: (msg) {
          _addMessage(ChatMessageSource.system, 'Provider error: $msg');
        },
        onSystemMessage: (msg) {
          _addMessage(ChatMessageSource.system, msg);
        },
        onInternalMessage: (msg) {
          _addMessage(ChatMessageSource.internal, msg);
        },
        onAuthToken: (token, url) async {
          // Always try to fetch models for any provider that has an inference client
          log('Auth token received - trying to fetch models');
          final state = _providerStates[providerId];
          if (state?.connection?.inferenceClient != null) {
            try {
              await modelsState.fetchModelsForProvider(
                providerId,
                state!.connection!.inferenceClient!,
              );
              log('Successfully fetched models for provider ${state.name}');
            } catch (e) {
              // Just log the error - this provider might not support models
              log('Note: Could not fetch models from provider: $e');
            }
          }
        },
        onPaymentConfirmed: () async {
          // Always try to fetch tools when payment is confirmed
          log('Payment confirmed - attempting to fetch tools');
          
          final state = _providerStates[providerId];
          if (state != null && state.connection != null) {
            try {
              // The provider connection will call _fetchToolsIfReady() internally
              // but we need to process the fetched tools to update the UI
              final tools = await state.connection!.fetchAvailableTools();
              if (tools.isNotEmpty) {
                state.availableTools = tools;
                log('Fetched ${tools.length} tools from provider ${state.name}');
                
                // Update the tools notifier to refresh the UI
                availableToolsNotifier.value = getAllAvailableTools();
              } else {
                log('No tools fetched from provider ${state.name}');
              }
            } catch (e) {
              // Just log the error - this provider might not support tools
              log('Note: Could not fetch tools from provider: $e');
            }
          }
        },
      );
      
      // Create or update provider state
      final state = ProviderState(
        id: providerId,
        name: name,
        wsUrl: wsUrl, 
        httpUrl: httpUrl,
        connection: connection,
      );
      _providerStates[providerId] = state;
      
      // Note: We previously set the active inference provider here, but that was too early
      // because we don't know if it supports inference yet. We now do this in _providerConnected
      // after capabilities have been established.

      // Request auth token - model fetch and tool fetch will happen in callback
      await connection.requestAuthToken();
      
      return true;
    } catch (e, stack) {
      log('Error connecting to provider: $e\n$stack');
      _addMessage(
          ChatMessageSource.system, 'Failed to connect to provider: $e');
      return false;
    }
  }

  // Handle provider connected event
  void _providerConnected(String providerId, [String name = '']) {
    final state = _providerStates[providerId];
    if (state != null) {
      state.connected = true;
      
      // If this provider supports inference, and we don't have an active inference provider yet,
      // set it as the active inference provider
      if (state.supportsInference && _activeInferenceProviderId == null) {
        log('Auto-setting active inference provider to ${state.name} (${state.id})');
        _activeInferenceProviderId = providerId;
      }
    }
    
    // For backward compatibility, if this is our active inference provider, call the callback
    if (providerId == _activeInferenceProviderId) {
      onProviderConnected();
    }
  }

  // Handle provider disconnected event
  void _providerDisconnected(String providerId) {
    final state = _providerStates[providerId];
    if (state != null) {
      state.connected = false;
    }
    
    // For backward compatibility, if this is our active inference provider, call the callback
    if (providerId == _activeInferenceProviderId) {
      _activeInferenceProviderId = null;
      onProviderDisconnected();
    }
  }

  // Set active inference provider
  void setActiveInferenceProvider(String providerId) {
    final state = _providerStates[providerId];
    if (state == null || !state.connected) {
      log('Cannot set active provider: provider not connected: $providerId');
      return;
    }
    
    // Check if this provider supports inference
    if (state.connection?.inferenceClient == null) {
      log('Cannot set active inference provider: provider does not support inference: $providerId');
      return;
    }
    
    _activeInferenceProviderId = providerId;
  }

  // Call a tool by name with the given arguments
  Future<ToolResult?> callTool(
    String toolName, 
    Map<String, dynamic> arguments, {
    String? toolCallId, // Add parameter for tool_call_id
  }) async {
    // First, find the correct provider for this tool
    final provider = getToolProvider(toolName);
    if (provider == null) {
      final errorMsg = 'No provider found for tool: $toolName';
      log(errorMsg);
      
      // Log detailed information for debugging
      final allTools = getAllAvailableTools();
      final toolNames = allTools.map((t) => t.name).join(', ');
      final providersWithTools = toolProviders.map((p) => 
          "${p.name}: [${p.availableTools.map((t) => t.name).join(', ')}]").join('; ');
      
      log('Available tools are: $toolNames');
      log('Providers with tools: $providersWithTools');
      
      _addMessage(
        ChatMessageSource.system,
        'Error: $errorMsg. Available tools: $toolNames',
      );
      return null;
    }
    
    // Check if the provider has an active connection
    if (provider.connection == null) {
      final errorMsg = 'Provider ${provider.name} for tool $toolName has no active connection';
      log(errorMsg);
      
      _addMessage(
        ChatMessageSource.system,
        errorMsg,
      );
      return null;
    }
    
    try {
      // CRITICAL FIX: Verify the provider has an auth token
      if (provider.connection!.inferenceClient?.authToken == null) {
        final errorMsg = 'Provider ${provider.name} for tool $toolName has no auth token';
        log(errorMsg);
        
        // Try to find any provider that has this tool AND has an auth token
        ProviderState? alternateProvider = null;
        for (final p in allProviders) {
          if (p.id != provider.id && 
              p.connected && 
              p.connection?.inferenceClient?.authToken != null &&
              p.availableTools.any((t) => t.name == toolName)) {
            alternateProvider = p;
            log('Found alternate provider ${p.name} with auth token and same tool');
            break;
          }
        }
        
        if (alternateProvider != null) {
          log('Using alternate provider ${alternateProvider.name} instead of ${provider.name} for tool $toolName');
          
          // Make the call with the alternate provider
          final result = await alternateProvider.connection!.callTool(toolName, arguments);
          
          // Log the provider switch 
          _addMessage(
            ChatMessageSource.tool,
            'Used tool: $toolName from alternate provider ${alternateProvider.name} (original provider lacked auth token)',
            metadata: {
              'tool_name': toolName,
              'arguments': arguments,
              'provider_id': alternateProvider.id,
              'provider_name': alternateProvider.name,
              'original_provider': provider.id,
              'actual_provider': result.providerId,
            },
          );
          
          return result;
        } else {
          _addMessage(
            ChatMessageSource.system,
            errorMsg,
          );
          return null;
        }
      }
      
      // For clarity in debugging, log that we're executing this tool call
      log('Executing tool call for $toolName on provider ${provider.name} (${provider.id})');
      
      // Log exactly what URL and auth token we're using to help diagnose connection issues
      final tokenPreview = provider.connection!.inferenceClient!.authToken!.substring(
          0, math.min(15, provider.connection!.inferenceClient!.authToken!.length));
      log('Using auth token prefix: ${tokenPreview}... for provider ${provider.name}');
      log('Provider URL: ${provider.httpUrl}');
      
      // IMPORTANT: Make a direct call to the selected provider's connection
      // Don't allow complex routing or delegation logic to interfere
      // Forward the toolCallId parameter to ensure it's preserved
      final result = await provider.connection!.callTool(
        toolName, 
        arguments, 
        toolCallId: toolCallId
      );
      
      // Add message to chat history about tool usage
      _addMessage(
        ChatMessageSource.tool,
        'Used tool: $toolName from provider ${provider.name}',
        metadata: {
          'tool_name': toolName,
          'arguments': arguments,
          'provider_id': provider.id,
          'provider_name': provider.name,
          'actual_provider': result.providerId,
        },
      );
      
      // Log the result for debugging
      String contentPreview;
      if (result.isSuccess && result.content.isNotEmpty) {
        if (result.content.first.text != null) {
          contentPreview = result.content.first.text!.substring(
            0, math.min(100, result.content.first.text!.length));
        } else {
          contentPreview = "non-text content";
        }
      } else if (!result.isSuccess) {
        contentPreview = "error: ${result.error?['message'] ?? 'unknown error'}";
      } else {
        contentPreview = 'empty result';
      }
      
      log('Tool $toolName returned result: $contentPreview');
      return result;
    } catch (e, stack) {
      final errorMsg = 'Error calling tool $toolName: $e';
      log('$errorMsg\n$stack');
      _addMessage(
        ChatMessageSource.system, 
        errorMsg,
      );
      return null;
    }
  }

  // Note: This method is exposed to the scripting environment.
  Future<ChatInferenceResponse?> sendMessagesToModel(
    List<ChatMessage> messages,
    String modelId,
    int? maxTokens,
  ) {
    final modelInfo = modelsState.getModelOrDefault(modelId);

    // Format messages for this model
    // Note: The default formatting logic knows how to render messages from foreign models
    // Note: as other "user" roles with prefixed model names.  The scripting environment
    // Note: can override this formatting by calling sendFormattedMessagesToModel() directly.
    final formattedMessages = modelInfo.formatMessages(messages);
    return sendFormattedMessagesToModel(formattedMessages, modelId, maxTokens);
  }

  // Note: This method is exposed to the scripting environment.
  Future<ChatInferenceResponse?> sendFormattedMessagesToModel(
    List<Map<String, dynamic>> formattedMessages,
    String modelId,
    int? maxTokens,
  ) async {
    // Make sure we check for an inference client
    if (!hasInferenceClient) {
      // Try to find the provider that has this model
      ProviderState? modelProvider;
      for (final state in _providerStates.values) {
        if (state.connected && state.supportsInference) {
          final providerModels = modelsState.getModelsForProvider(state.id);
          if (providerModels.any((model) => model.id == modelId)) {
            log('Found provider ${state.name} for model $modelId');
            modelProvider = state;
            // Auto-set this as active inference provider
            _activeInferenceProviderId = state.id;
            break;
          }
        }
      }
      
      // If we still can't find a provider for this model, report error
      if (modelProvider == null) {
        log('No provider found for model: $modelId');
        _addMessage(ChatMessageSource.system, 'No provider found for model: $modelId');
        return null;
      }
    }
    
    // Double-check that we have a provider connection
    if (_activeInferenceProviderId == null || 
        _providerStates[_activeInferenceProviderId]?.connection == null) {
      log('No active inference provider connection');
      _addMessage(ChatMessageSource.system, 'No active inference provider connection');
      return null;
    }
  
    // Prepare API parameters
    Map<String, Object> params = {};
    if (maxTokens != null) {
      params['max_tokens'] = maxTokens;
    }
    
    // IMPORTANT: Enable tool routing at the backend
    params['route_tool_calls'] = true;

    final modelInfo = modelsState.getModelOrDefault(modelId);
    _addMessage(
      ChatMessageSource.internal,
      'Querying ${modelInfo.name} from provider ${_providerStates[_activeInferenceProviderId]!.name}...',
      modelId: modelInfo.id,
      modelName: modelInfo.name,
    );

    final connection = _providerStates[_activeInferenceProviderId]!.connection!;
    
    // Before sending the request, collect comprehensive tool provider routing information
    final enabledTools = getEnabledTools();
    if (enabledTools.isNotEmpty) {
      // Build a detailed mapping of tools to their providers
      final toolProviderMap = <String, Map<String, dynamic>>{};
      
      log('Preparing tool routing information for ${enabledTools.length} enabled tools');
      
      for (var tool in enabledTools) {
        final provider = getToolProvider(tool.name);
        if (provider != null) {
          // Validate that this provider has an auth token before adding it
          bool hasAuthToken = provider.connection?.inferenceClient?.authToken != null;
          
          if (hasAuthToken) {
            // Create a complete provider routing entry with all necessary information
            toolProviderMap[tool.name] = {
              'provider_id': provider.id,
              'provider_name': provider.name,
              'provider_url': provider.httpUrl,
              'is_tools_only': provider.isToolsOnlyProvider.toString(),
              'auth_token_available': 'true'
            };
            
            log('Tool ${tool.name} will be routed to provider ${provider.name} (${provider.id})');
          } else {
            // Try to find another provider that has this tool AND has an auth token
            log('Provider ${provider.name} for tool ${tool.name} has no auth token - looking for alternative');
            
            ProviderState? alternateProvider = null;
            for (final p in allProviders) {
              if (p.id != provider.id && 
                 p.connected && 
                 p.connection?.inferenceClient?.authToken != null &&
                 p.availableTools.any((t) => t.name == tool.name)) {
                alternateProvider = p;
                log('Found alternate provider ${p.name} with auth token and same tool');
                break;
              }
            }
            
            if (alternateProvider != null) {
              toolProviderMap[tool.name] = {
                'provider_id': alternateProvider.id,
                'provider_name': alternateProvider.name,
                'provider_url': alternateProvider.httpUrl,
                'is_tools_only': alternateProvider.isToolsOnlyProvider.toString(),
                'auth_token_available': 'true',
                'original_provider': provider.id,
              };
              
              log('Will route tool ${tool.name} to alternate provider ${alternateProvider.name} instead of ${provider.name}');
            } else {
              // Still include the original provider but mark it as not having an auth token
              toolProviderMap[tool.name] = {
                'provider_id': provider.id,
                'provider_name': provider.name,
                'provider_url': provider.httpUrl,
                'is_tools_only': provider.isToolsOnlyProvider.toString(),
                'auth_token_available': 'false'
              };
              
              log('Warning: Provider ${provider.name} for tool ${tool.name} has no auth token and no alternatives found');
            }
          }
        } else {
          log('Warning: No provider found for tool ${tool.name} - tool may not work correctly');
        }
      }
      
      // Add the comprehensive tool provider routing map to the request parameters
      if (toolProviderMap.isNotEmpty) {
        params['tool_providers'] = toolProviderMap;
        log('Added routing information for ${toolProviderMap.length} tools to inference request');
      }
    } else {
      log('No enabled tools to include in inference request');
    }
    
    // Send the inference request with the enhanced parameters
    return connection.requestInference(
      modelInfo.id,
      formattedMessages,
      params: params,
    );
  }
  
  // Method to handle explicit tool routing based on provider ID
  Future<ToolResult?> routeToolCallToProvider(
    String toolName, 
    Map<String, dynamic> arguments,
    String requestedProviderId
  ) async {
    log('Explicit tool routing request: Tool $toolName to provider $requestedProviderId');
    
    // First check if the requested provider exists and is connected
    final requestedProvider = _providerStates[requestedProviderId];
    if (requestedProvider == null || !requestedProvider.connected || requestedProvider.connection == null) {
      log('Requested provider $requestedProviderId not available (connected: ${requestedProvider?.connected}, has connection: ${requestedProvider?.connection != null})');
      
      // Fall back to standard tool routing which will find the best provider
      log('Falling back to standard tool routing');
      return callTool(toolName, arguments);
    }
    
    // Check if this provider has an auth token for making tool calls
    if (requestedProvider.connection!.inferenceClient?.authToken == null) {
      log('Requested provider $requestedProviderId has no auth token, cannot call tools');
      
      // Fall back to standard tool routing which will find an authenticated provider
      log('Falling back to standard tool routing to find an authenticated provider');
      return callTool(toolName, arguments);
    }
    
    // Make the direct call to the specified provider
    try {
      log('Executing tool $toolName directly on explicitly requested provider ${requestedProvider.name}');
      
      // Make a direct call to the provider's connection
      final result = await requestedProvider.connection!.callTool(toolName, arguments);
      
      // Add message to chat history about this explicit tool routing
      _addMessage(
        ChatMessageSource.tool,
        'Used tool: $toolName from explicitly requested provider ${requestedProvider.name}',
        metadata: {
          'tool_name': toolName,
          'arguments': arguments,
          'provider_id': requestedProvider.id,
          'provider_name': requestedProvider.name,
          'explicit_routing': true,
        },
      );
      
      // Log the result for debugging
      String contentPreview = "unknown result";
      if (result.isSuccess && result.content.isNotEmpty) {
        if (result.content.first.text != null) {
          contentPreview = result.content.first.text!.substring(
            0, math.min(100, result.content.first.text!.length));
        } else {
          contentPreview = "non-text content";
        }
      } else if (!result.isSuccess) {
        contentPreview = "error: ${result.error?['message'] ?? 'unknown error'}";
      }
      
      log('Explicit tool routing for $toolName returned: $contentPreview');
      return result;
    } catch (e, stack) {
      final errorMsg = 'Error in explicit tool routing for $toolName on provider ${requestedProvider.name}: $e';
      log('$errorMsg\n$stack');
      
      _addMessage(
        ChatMessageSource.system, 
        'Tool error (explicit routing): $e',
      );
      
      // Fall back to standard tool routing as a last resort
      log('Falling back to standard tool routing after explicit routing failed');
      return callTool(toolName, arguments);
    }
  }

  // New format: Parses providers list from environment variables
  static Map<String, Map<String, dynamic>> getFromEnv() {
    final providersJson =
        const String.fromEnvironment('PROVIDERS', defaultValue: '[]');
    log('Provider config from environment: $providersJson');
    
    try {
      // Parse providers as a JSON array of objects
      final List<dynamic> providersList = json.decode(providersJson);
      final providers = <String, Map<String, dynamic>>{};
      
      // Convert array to map with generated IDs
      for (int i = 0; i < providersList.length; i++) {
        final provider = providersList[i] as Map<String, dynamic>;
        final id = 'env-provider-$i';
        
        providers[id] = {
          'url': provider['url'] as String? ?? '',
          'name': provider['name'] as String? ?? 'Provider $i',
        };
      }
      
      return providers;
    } catch (e) {
      log('Error parsing providers configuration: $e');
      return {};
    }
  }
  
  // Get providers from URL parameters (format: providers=name1:url1,name2:url2)
  static Map<String, Map<String, dynamic>> getFromUrlParams() {
    // Get URL parameters
    final uri = Uri.base;
    final providerParam = uri.queryParameters['providers'];
    if (providerParam == null || providerParam.isEmpty) {
      return {};
    }
    
    final providers = <String, Map<String, dynamic>>{};
    try {
      // Format is name1:url1,name2:url2
      final providerPairs = providerParam.split(',');
      for (final pair in providerPairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final name = parts[0];
          final url = parts[1];
          final id = 'url-param-${DateTime.now().millisecondsSinceEpoch}-${providers.length}';
          providers[id] = {
            'name': name,
            'url': url,
          };
          log('Added provider from URL: $name, $url');
        }
      }
    } catch (e) {
      log('Error parsing providers from URL: $e');
    }
    
    return providers;
  }
}