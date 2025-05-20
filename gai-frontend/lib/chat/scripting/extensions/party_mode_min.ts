// Implement "party mode" chat command

/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

function onUserPrompt(userPrompt: string): void {
    (async () => {
        chatClientMessage(userPrompt)
        for (const model of getUserSelectedModels()) {
            addChatMessage(await chatSendToModel(getConversation(), model.id));
        }
    })();
}
