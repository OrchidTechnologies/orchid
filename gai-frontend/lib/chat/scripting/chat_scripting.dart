import 'package:orchid/chat/chat_history.dart';
import 'package:orchid/chat/chat_message.dart';
import 'package:orchid/chat/model.dart';
import 'package:orchid/chat/provider_manager.dart';
import 'package:orchid/gui-orchid/lib/orchid/orchid.dart';
import 'dart:js_interop';
import 'chat_bindings_js.dart';
import 'chat_message_js.dart';
import 'model_info_js.dart';
import 'package:http/http.dart' as http;


class ChatScripting {

  static ChatScripting? _instance;

  static ChatScripting get instance {
    if (_instance == null) {
      throw Exception("ChatScripting not initialized!");
    }
    return _instance!;
  }

  static bool get enabled => _instance != null;

  late String script;
  late ProviderManager providerManager;
  late ChatHistory chatHistory;
  late void Function(ChatMessage) addChatMessageToUI;
  late bool debugMode;

  static Future<void> init({
    // The URL from which to load the script
    required String url,

    // If debugMode is true, the script will be re-loaded before each invocation
    bool debugMode = false,

    required ProviderManager providerManager,
    required ChatHistory chatHistory,
    required Function(ChatMessage) addChatMessageToUI,
  }) async {
    if (_instance != null) {
      throw Exception("ChatScripting already initialized!");
    }

    _instance = ChatScripting();
    instance.debugMode = debugMode;
    instance.providerManager = providerManager;
    instance.chatHistory = chatHistory;
    instance.addChatMessageToUI = addChatMessageToUI;

    // Install persistent callback functions
    doGlobalSetup();

    await instance.loadExtensionScript(url);
    // Do one setup and evaluation of the script now
    instance.doPerCallSetup();
  }

  Future<void> loadExtensionScript(String url) async {
    // Load the script from the URL as a string
    log("Loading script from $url");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception("Failed to load script from $url: ${response.statusCode}");
    }

    // If the result is HTML we have failed
    if (response.headers['content-type']!.contains('text/html')) {
      throw Exception("Failed to load script from $url: HTML response: ${response.body.truncate(64)}");
    }

    script = response.body;
    // log("Loaded script: $script");
  }

  void evalExtensionScript() {
    try {
      final result = evaluateJS(script);
      log("Evaluated script: $result, ${result.runtimeType}");
    } catch (e, stack) {
      log("Failed to evaluate script: $e");
      log(stack.toString());
    }
  }

  // Install the persistent callback functions
  static void doGlobalSetup() {
    addChatMessageJS = instance.addChatMessageFromJS.toJS;
    sendMessagesToModelJS = instance.sendMessagesToModelFromJS.toJS;
  }

  // Items that need to be copied before each invocation of the JS scripting extension
  void doPerCallSetup({List<ModelInfo>? userSelectedModels}) {
    chatHistoryJS =
        ChatMessageJS.fromChatMessages(chatHistory.messages).jsify() as JSArray;
    userSelectedModelsJS =
        ModelInfoJS.fromModelInfos(userSelectedModels ?? []).jsify() as JSArray;
    if (debugMode) {
      evalExtensionScript();
    }
  }

  // Send the user prompt to the JS scripting extension
  void sendUserPrompt(String userPrompt, List<ModelInfo> userSelectedModels) {
    log("Invoke onUserPrompt on the scripting extension: $userPrompt");
    doPerCallSetup(userSelectedModels: userSelectedModels);
    onUserPromptJS(userPrompt);
  }

  ///
  /// BEGIN: callbacks from JS
  ///

  // Implementation of the addChatMessage callback function invoked from JS
  // Add a chat message to the local history.
  void addChatMessageFromJS(ChatMessageJS message) {
    log("Add chat message: ${message.source}, ${message.msg}");
    addChatMessageToUI(ChatMessageJS.toChatMessage(message));
  }

  // Implementation of sendMessagesToModel callback function invoked from JS
  // Send a list of ChatMessage to a model for inference
  String sendMessagesToModelFromJS(JSArray messagesJS, String modelId, int? maxTokens) {
    final List<ChatMessageJS> listJS = (messagesJS.dartify() as List).cast<ChatMessageJS>();
    final List<ChatMessage> messages = ChatMessageJS.toChatMessages(listJS);
    log("Send messages to model: $modelId, ${messages.length} messages");
    if (messages.isNotEmpty) {
      log("messages[0] = ${messages[0]}");
    }
    return "result from dart";
  }

}
