import 'package:orchid/chat/chat_history.dart';
import 'package:orchid/chat/chat_message.dart';
import 'package:orchid/chat/model.dart';
import 'package:orchid/chat/model_manager.dart';
import 'package:orchid/chat/provider_connection.dart';
import 'package:orchid/chat/provider_manager.dart';
import 'package:orchid/gui-orchid/lib/orchid/orchid.dart';
import 'dart:js_interop';
import 'chat_bindings_js.dart';
import 'chat_message_js.dart';
import 'model_info_js.dart';
import 'package:http/http.dart' as http;

class ChatScripting {
  // Singleton
  static ChatScripting? _instance;

  static ChatScripting get instance {
    if (_instance == null) {
      throw Exception("ChatScripting not initialized!");
    }
    return _instance!;
  }

  static bool get enabled => _instance != null;

  // Scripting State
  String? script;
  late ProviderManager providerManager;
  late ModelManager modelManager;
  late List<ModelInfo> Function() getUserSelectedModels;
  late ChatHistory chatHistory;
  late void Function(ChatMessage) addChatMessageToUI;
  late bool debugMode;

  static Future<void> init({
    // A script
    String? script,

    // The URL from which to load the script
    String? url,

    // If debugMode is true, the script will be re-loaded before each invocation
    bool debugMode = false,
    required ProviderManager providerManager,
    required ChatHistory chatHistory,
    required ModelManager modelManager,
    required List<ModelInfo> Function() getUserSelectedModels,
    required Function(ChatMessage) addChatMessageToUI,
  }) async {
    if (_instance != null) {
      throw Exception("ChatScripting already initialized!");
    }

    _instance = ChatScripting();
    instance.debugMode = debugMode;
    instance.providerManager = providerManager;
    instance.chatHistory = chatHistory;
    instance.modelManager = modelManager;
    instance.getUserSelectedModels = getUserSelectedModels;
    instance.addChatMessageToUI = addChatMessageToUI;

    if (url != null) {
      // Install persistent callback functions
      final script = await instance.loadScriptFromURL(url);
      instance.setScript(script);
    }

    if (script != null) {
      instance.setScript(script);
    }
  }

  // Set the script into the environment
  void setScript(String newScript) {
    // init the global bindings once, when we have a script
    if (script == null) {
      addGlobalBindings();
    }
    script = newScript;
    // Do one setup and evaluation of the script now
    evalExtensionScript();
  }

  Future<String> loadScriptFromURL(String url) async {
    // Load the script from the URL as a string
    log("Loading script from $url");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to load script from $url: ${response.statusCode}");
    }

    // If the result is HTML we have failed
    if (response.headers['content-type']!.contains('text/html')) {
      throw Exception(
          "Failed to load script from $url: HTML response: ${response.body.truncate(64)}");
    }

    // log("Loaded script: $script");
    return response.body;
  }

  void evalExtensionScript() {
    // Wrap the script in an async function to allow top level await without messing with modules.
    // final wrappedScript = "(async () => {$script})();";
    try {
      if (script == null) {
        throw Exception("No script to evaluate.");
      }
      evaluateJS(script!); // We could get a result back async here if needed
    } catch (e, stack) {
      log("Failed to evaluate script: $e");
      log(stack.toString());
    }
  }

  // Install the persistent callback functions
  static void addGlobalBindings() {
    addChatMessageJS = instance.addChatMessageJSImpl.toJS;
    sendMessagesToModelJS = instance.sendMessagesToModelJSImpl.toJS;
    getChatHistoryJS = instance.getChatHistoryJSImpl.toJS;
    getUserSelectedModelsJS = instance.getUserSelectedModelsJSImpl.toJS;
  }

  // Send the user prompt to the JS scripting extension
  void sendUserPrompt(String userPrompt, List<ModelInfo> userSelectedModels) {
    log("Invoke onUserPrompt on the scripting extension: $userPrompt");

    // If debug mode evaluate the script before each usage
    if (debugMode) {
      evalExtensionScript();
    }

    onUserPromptJS(userPrompt);
  }

  ///
  /// BEGIN: JS callback implementations
  ///

  // Implementation of the getChatHistory callback function invoked from JS
  JSArray getChatHistoryJSImpl() =>
      ChatMessageJS.fromChatMessages(chatHistory.messages).jsify() as JSArray;

  // Implementation of the getUserSelectedModels callback function invoked from JS
  JSArray getUserSelectedModelsJSImpl() =>
      ModelInfoJS.fromModelInfos(getUserSelectedModels()).jsify() as JSArray;

  // Implementation of the addChatMessage callback function invoked from JS
  // Add a chat message to the local history.
  void addChatMessageJSImpl(ChatMessageJS message) {
    log("Add chat message: ${message.source}, ${message.msg}");
    addChatMessageToUI(ChatMessageJS.toChatMessage(message));
  }

  // Implementation of sendMessagesToModel callback function invoked from JS
  // Send a list of ChatMessage to a model for inference and return a promise of ChatMessageJS
  JSPromise sendMessagesToModelJSImpl(
      JSArray messagesJS, String modelId, int? maxTokens) {
    log("dart: Send messages to model called.");

    return (() async {
      try {
        final listJS = (messagesJS.toDart).cast<ChatMessageJS>();
        final List<ChatMessage> messages = ChatMessageJS.toChatMessages(listJS);
        log("messages = $messages");

        if (messages.isEmpty) {
          log("No messages to send.");
          // Wow: If you forget the .jsify() here the promise will crash, even if this
          // code path is not executed.
          return null.jsify();
        }

        // log("dart: simulate delay");
        // await Future.delayed(const Duration(seconds: 2));
        // log("dart: after delay response from sendMessagesToModel sent.");
        // return ["message 1", "message 2"].jsify(); // Don't forget value to JS

        // Send the messages to the model
        final ChatInferenceResponse? response = await providerManager
            .sendMessagesToModel(messages, modelId, maxTokens);
        if (response == null) {
          log("No response from model.");
          return null.jsify();
        }

        return ChatMessageJS.fromChatMessage(response.toChatMessage()).jsify();
      } catch (e, stack) {
        log("Failed to send messages to model: $e");
        log(stack.toString());
        return null.jsify();
      }
    })()
        .toJS;
  }

  ///
  /// END: JS callback implementations
  ///
}
