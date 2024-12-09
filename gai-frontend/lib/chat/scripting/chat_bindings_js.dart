import 'dart:js_interop';
import 'chat_message_js.dart';

// Expose the JS 'eval' function to Dart
@JS('eval')
external JSAny? evaluateJS(String jsCode);

// Setter to install the chatHistory variable in JS
// let chatHistory: ReadonlyArray<ChatMessage>;
@JS('chatHistory')
external set chatHistoryJS(JSArray value);

// Setter to install the userSelectedModels variable in JS
// List of ModelInfo user-selected models, read-only
@JS('userSelectedModels')
external set userSelectedModelsJS(JSArray value);

// Setter to install the sendMessagesToModel callback function in JS
// Send a list of ChatMessage to a model for inference
// function sendMessagesToModel( messages: Array<ChatMessage>, modelId: string, maxTokens?: number, ) : Promise<string[]>
@JS('sendMessagesToModel')
external set sendMessagesToModelJS(JSFunction value);

// Setter to install the sendFormattedMessagesToModel callback function in JS
// Send a list of formatted messages to a model for inference
// function sendFormattedMessagesToModel( formattedMessages: Array<Object>, modelId: string, maxTokens?: number, ): void
@JS('sendFormattedMessagesToModel')
external set sendFormattedMessagesToModelJS(JSFunction value);

// Setter to install the addChatMessage function in JS
// Add a chat message to the local history
// function addChatMessage(chatMessage: ChatMessage): void
@JS('addChatMessage')
external set addChatMessageJS(JSFunction value);

// Extension entry point: The user has hit enter on a new prompt.
// Callable from Dart like `onUserPrompt('Some prompt text');`
@JS('onUserPrompt')
external void onUserPromptJS(String userPrompt);

// Extension entry point: A response came back from inference.
// Callable from Dart like `onChatResponse(responseMessage);`
@JS('onChatResponse')
external void onChatResponseJS(ChatMessageJS chatResponse);

