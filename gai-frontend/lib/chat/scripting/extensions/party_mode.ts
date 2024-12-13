// Implement "party mode" chat command

/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

// Main entry point when the user has hit enter on a new prompt
function onUserPrompt(userPrompt: string): void {
    (async () => {
        chatSystemMessage('Extension: Party mode invoked');
        chatClientMessage(userPrompt)

        // Gather messages of source type 'client' or 'provider', irrespective of the model
        // (Same as getConversation(), doing this for illustration)
        const filteredMessages = getChatHistory().filter(
            (message) =>
                message.source === ChatMessageSource.CLIENT ||
                message.source === ChatMessageSource.PROVIDER
        );

        // Send to each user-selected model
        for (const model of getUserSelectedModels()) {
            console.log(`party_mode: Sending messages to model: ${model.name}`);
            await chatSendToModel(filteredMessages, model.id);
        }
    })();
}

