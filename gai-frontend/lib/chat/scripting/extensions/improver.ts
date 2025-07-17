/// An extension that improves user prompts using Claude before sending to the selected model.
/// <reference path="../chat_scripting_api.ts" />

function onUserPrompt(userPrompt: string): void {
    (async () => {
        chatSystemMessage('Extension: Prompt Improver');

        // Create a message asking Claude to improve the prompt
        const improvementMessage = new ChatMessage(
            ChatMessageSource.CLIENT,
            `You are a prompt improvement assistant. Your task is to improve the following prompt to be ` +
            `more specific, clear, and effective. Maintain the original intent but make it more detailed ` +
            `and precise. Respond with only the improved prompt, no explanations: ` +
            `{BEGIN_PROMPT}${userPrompt}{END_PROMPT}`,
            {}
        );

        // Send to Claude for improvement
        const improvedResponse = await chatSendToModel([improvementMessage], 'claude-3-5-sonnet-latest');
        const improvedPrompt = improvedResponse.msg.trim();

        // Log the original and improved prompts
        chatSystemMessage(`Original prompt: ${userPrompt}`);
        chatInternalMessage(`Improved prompt: ${improvedPrompt}`);

        // Create a message with the improved prompt
        const userMessage = new ChatMessage(ChatMessageSource.CLIENT, improvedPrompt, {});
        addChatMessage(userMessage);

        // Send to the first user-selected model
        const modelId = getUserSelectedModels()[0].id;
        addChatMessage(await sendMessagesToModel([userMessage], modelId, null));
    })();
}
