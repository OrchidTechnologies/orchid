/// An example of sending the user prompt to another model for validation before the user-selected model.

/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

function onUserPrompt(userPrompt: string): void {
    (async () => {
        // Log a system message to the chat
        chatSystemMessage('Extension: Filter Example');

        // Send the message to 'gpt-4o' and ask it to characterize the user prompt.
        let decisionMessage = new ChatMessage(ChatMessageSource.CLIENT,
            `The following is a user-generated prompt.  Please characterize it as either friendly or ` +
            `unfriendly and respond with just your one word decision: ` +
            `{BEGIN_PROMPT}${userPrompt}{END_PROMPT}`,
            {});
        let response = await chatSendToModel([decisionMessage], 'gpt-4o');
        let decision = response.msg.trim().toLowerCase();

        // Log the decision to the chat
        chatSystemMessage(`Extension: User prompt evaluated as: ${decision}`);

        // Add the user prompt to the chat
        let userMessage = new ChatMessage(ChatMessageSource.CLIENT, userPrompt, {});
        addChatMessage(userMessage);

        // Send it to the first user-selected model
        const modelId = getUserSelectedModels()[0].id;
        addChatMessage(await sendMessagesToModel([userMessage], modelId, null));

    })();
}

