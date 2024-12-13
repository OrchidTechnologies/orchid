/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

(async () => {
    console.log('test_script: Evaluating JavaScript code from Dart...');
    console.log('test_script: Chat History:', chatHistory);

    const chatMessage = new ChatMessage(ChatMessageSource.SYSTEM, 'Extension: Test Script', {'foo': 'bar'});
    addChatMessage(chatMessage);

    const promise = sendMessagesToModel([chatMessage], 'test-model', null);
    const result = await promise;
    console.log(`test_script: awaited 2 sendMessagesToModel. Result from dart: ${result}`);

    return 42;
})();

