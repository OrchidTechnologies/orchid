// Implement "party mode" chat command

/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

// Main entry point when the user has hit enter on a new prompt
function onUserPrompt(userPrompt: string): void {
    (async () => {
        addChatMessage(new ChatMessage(ChatMessageSource.SYSTEM, 'Extension: Party mode invoked', {}));
        addChatMessage(new ChatMessage(ChatMessageSource.CLIENT, userPrompt, {}));

        throw new Error('History is not currently updated, fix this...');

        // Gather messages of source type 'client' or 'provider', irrespective of the model
        // [See getConversation()]
        const filteredMessages = chatHistory.filter(
            (message) =>
                message.source === ChatMessageSource.CLIENT ||
                message.source === ChatMessageSource.PROVIDER
        );

        // Send to each user-selected model
        for (const model of userSelectedModels) {
            console.log(`party_mode: Sending messages to model: ${model.name}`);
            await sendMessagesToModel(filteredMessages, model.id, null);
        }
    })();
}

