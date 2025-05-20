// A TS API for the chat scripting environment
// This is compiled to JS by the build script and included in the html for basic structural type info.
// See chat_scripting_bindings_js.dart for the dart bindings.

enum ChatMessageSource {
    CLIENT = 'client',
    PROVIDER = 'provider',
    SYSTEM = 'system',
    INTERNAL = 'internal',
}

class ChatMessage {
    source: ChatMessageSource; // Source of the chat message
    msg: string; // Message content
    metadata: Record<string, any>; // Metadata associated with the message

    constructor(source: ChatMessageSource, msg: string, metadata: Record<string, any>) {
        this.source = source;
        this.msg = msg;
        this.metadata = metadata;
    }
}

class ModelInfo {
    id: string; // Unique identifier for the model
    name: string; // Name of the model
    provider: string; // Provider of the model
    apiType: string; // API type for the model

    constructor(id: string, name: string, provider: string, apiType: string) {
        this.id = id;
        this.name = name;
        this.provider = provider;
        this.apiType = apiType;
    }
}

// List of ChatMessage structs, read-only
declare function getChatHistory(): ReadonlyArray<ChatMessage>;

// List of ModelInfo user-selected models, read-only
declare function getUserSelectedModels(): ReadonlyArray<ModelInfo>;

// Send a list of ChatMessage to a model for inference
declare function sendMessagesToModel(
    messages: Array<ChatMessage>,
    modelId: string,
    maxTokens: number | null,
): Promise<ChatMessage>;

// Send a list of formatted messages to a model for inference
declare function sendFormattedMessagesToModel(
    formattedMessages: Array<Object>,
    modelId: string,
    maxTokens?: number,
): Promise<ChatMessage>;

// Add a chat message to the history
declare function addChatMessage(chatMessage: ChatMessage): void

// @ts-ignore
// Extension entry point: The user has hit enter on a new prompt.
declare function onUserPrompt(userPrompt: string): void

//
// Helper / util implementations
//

// Add a system message to the chat
function chatSystemMessage(message: string): void {
    addChatMessage(new ChatMessage(ChatMessageSource.SYSTEM, message, {}));
}
// Add a provider message to the chat
function chatProviderMessage(message: string): void {
    addChatMessage(new ChatMessage(ChatMessageSource.PROVIDER, message, {}));
}
// Add an internal message to the chat
function chatInternalMessage(message: string): void {
    addChatMessage(new ChatMessage(ChatMessageSource.INTERNAL, message, {}));
}
// Add a client message to the chat
function chatClientMessage(message: string): void {
    addChatMessage(new ChatMessage(ChatMessageSource.CLIENT, message, {}));
}

// Send a list of messages to a model for inference
function chatSendToModel(
    messages: Array<ChatMessage>,
    modelId: string,
    maxTokens: number | null = null,
): Promise<ChatMessage> {
    return sendMessagesToModel(messages, modelId, maxTokens);
}

// Get the conversation history for all models
function getConversation(): Array<ChatMessage> {
    // Gather messages of source type 'client' or 'provider', irrespective of the provider model
    return getChatHistory().filter(
        (message) =>
            message.source === ChatMessageSource.CLIENT ||
            message.source === ChatMessageSource.PROVIDER
    );
}

console.log('Chat Scripting API loaded');