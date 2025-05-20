// Implement "party mode" chat command

/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

// Main entry point when the user has hit enter on a new prompt
function onUserPrompt(userPrompt: string): void {
    (async () => {
        chatSystemMessage('Extension: Party mode invoked');
        chatClientMessage(userPrompt)

        // Send to each user-selected model in turn
        for (const model of getUserSelectedModels()) {
            // Gather all messages of source type 'client' or 'provider', irrespective of source model.
            // (Doing this inside the loop allows the models to see the previous models responses.)
            const filteredMessages = getChatHistory().filter(
                (message) =>
                    message.source === ChatMessageSource.CLIENT ||
                    message.source === ChatMessageSource.PROVIDER
            );

            // Send the messages to the model and add the response to the chat
            console.log(`party_mode: Sending messages to model: ${model.name}`);
            const response = await chatSendToModel(filteredMessages, model.id);
            addChatMessage(response);
        }
    })();
}