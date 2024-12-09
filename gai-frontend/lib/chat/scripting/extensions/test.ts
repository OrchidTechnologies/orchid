/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

console.log('Test Script: Evaluating JavaScript code from Dart...');

console.log('Chat History:', chatHistory);

const chatMessage = new ChatMessage(
    ChatMessageSource.SYSTEM,
    'Extension: Test Script',
    {'foo': 'bar'}
);
addChatMessage(chatMessage);

var result = sendMessagesToModel([chatMessage], 'test-model', 999);
console.log('sendMessagesToModel Result from dart:', result);

// Return a result
const returnResult = 42;
returnResult;
