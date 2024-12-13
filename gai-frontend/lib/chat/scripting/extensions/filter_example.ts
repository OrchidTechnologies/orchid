/// An example of sending the user prompt to another model for validation before the user-selected model.

/// Let the IDE see the types from the chat_scripting_api during development.
/// <reference path="../chat_scripting_api.ts" />

function onUserPrompt(userPrompt: string): void {
    (async () => {
        // Log a system message to the chat
        addChatMessage(new ChatMessage(ChatMessageSource.SYSTEM, 'Extension: Filter Example', {}));

        // Send the message to 'gpt-4o' and ask it to characterize the user prompt.
        let message = new ChatMessage(ChatMessageSource.CLIENT,
            `The following is a user-generated prompt.  Please characterize it as either friendly or ` +
            `unfriendly and respond with just your one word decision: ` +
            `{BEGIN_PROMPT}${userPrompt}{END_PROMPT}`,
            {});
        let response = await sendMessagesToModel([message], 'gpt-4o', null);
        let decision = response.msg.trim().toLowerCase();

        // Log the decision to the chat
        addChatMessage(new ChatMessage(ChatMessageSource.SYSTEM,
            `Extension: User prompt evaluated as: ${decision}`, {}));

        // Now send the prompt to the first user-selected model
        const modelId = userSelectedModels[0].id;
        message = new ChatMessage(ChatMessageSource.CLIENT, userPrompt, {});
        addChatMessage(await sendMessagesToModel([message], modelId, null));

    })();
}

