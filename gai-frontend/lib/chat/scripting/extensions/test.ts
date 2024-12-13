/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

function onUserPrompt(userPrompt: string): void {
    (async () => {
        console.log('test_script: Chat History:', getChatHistory());
        console.log('test_script: User Selected Models:', getUserSelectedModels());

        const chatMessage = new ChatMessage(ChatMessageSource.SYSTEM, 'Extension: Test Script', {'foo': 'bar'});
        addChatMessage(chatMessage);

        return 42;
    })();
}
