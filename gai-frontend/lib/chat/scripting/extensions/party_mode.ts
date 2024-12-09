// Implement "party mode" chat command

/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

// Main entry point when the user has hit enter on a new prompt
function onUserPrompt(userPrompt: string): void {
    (async () => {
        console.log(`Party mode: on user prompt: ${userPrompt}`);
        addChatMessage(new ChatMessage(ChatMessageSource.SYSTEM, 'Extension: Party mode invoked', {}));
        addChatMessage(new ChatMessage(ChatMessageSource.CLIENT, userPrompt, {}));

        console.log("party_mode: chatHistory: ", chatHistory);
        // Gather messages of source type 'client' or 'provider', irrespective of the model
        const filteredMessages = chatHistory.filter(
            (message) =>
                message.source === ChatMessageSource.CLIENT ||
                message.source === ChatMessageSource.PROVIDER
        );
        console.log(`party_mode: Filtered messages: ${filteredMessages}`, filteredMessages);

        // Send them to all user-selected models
        for (const model of userSelectedModels) {
            console.log(`party_mode: Sending messages to model: ${model.name}`);
            const promise = sendMessagesToModel(filteredMessages, model.id, null);
            console.log(`party_mode: promise for model ${model.name}: ${promise}`, promise);
            const result = await promise;
        }
    })();
}

