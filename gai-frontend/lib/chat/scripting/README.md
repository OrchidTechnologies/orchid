# Frontend Scripting Engine Documentation

## Overview

The Frontend Scripting Engine is a powerful extension system that allows users to customize and enhance the chat interface behavior by loading custom TypeScript/JavaScript scripts. These scripts can intercept user prompts, modify messages, interact with different AI models, and control the chat flow.

### Key Features

- **Dynamic Script Loading**: Scripts can be loaded from URLs or directly as strings
- **Hot Reloading**: Debug mode supports script reloading before each invocation
- **Multi-Model Support**: Scripts can send messages to any available model
- **Full Chat Control**: Add messages, read history, and manipulate the conversation flow
- **TypeScript Support**: Full type definitions for a great development experience

## Architecture

The scripting engine consists of three main components:

### 1. Dart/Flutter Layer (`chat_scripting.dart`)
- Manages script lifecycle (loading, evaluation, error handling)
- Provides singleton access pattern for global state management
- Bridges between Flutter UI and JavaScript execution context
- Handles script loading from URLs with proper error handling

### 2. JavaScript Bindings (`chat_bindings_js.dart`)
- Defines the interface between Dart and JavaScript
- Exposes Dart functions to JavaScript context
- Manages type conversions between Dart and JS

### 3. TypeScript API (`chat_scripting_api.ts`)
- Provides type definitions for script development
- Defines available hooks and helper functions
- Ensures type safety during development

## Available Hooks and Functions

### Primary Hook

#### `onUserPrompt(userPrompt: string): void`
The main entry point called when a user submits a new prompt. This is where your script logic begins.

```typescript
function onUserPrompt(userPrompt: string): void {
    // Your script logic here
}
```

### Core Functions

#### `getChatHistory(): ReadonlyArray<ChatMessage>`
Returns the complete chat history as a read-only array of messages.

#### `getUserSelectedModels(): ReadonlyArray<ModelInfo>`
Returns information about models selected by the user in the UI.

#### `sendMessagesToModel(messages: Array<ChatMessage>, modelId: string, maxTokens: number | null): Promise<ChatMessage>`
Sends messages to a specific model and returns the response.

#### `addChatMessage(chatMessage: ChatMessage): void`
Adds a message to the chat history and UI.

### Helper Functions

#### `chatSystemMessage(message: string): void`
Adds a system message to the chat (displayed as system notification).

#### `chatProviderMessage(message: string): void`
Adds a provider/model response message.

#### `chatInternalMessage(message: string): void`
Adds an internal message (typically for debugging or logging).

#### `chatClientMessage(message: string): void`
Adds a client/user message to the chat.

#### `chatSendToModel(messages: Array<ChatMessage>, modelId: string, maxTokens?: number): Promise<ChatMessage>`
Convenience wrapper for `sendMessagesToModel`.

#### `getConversation(): Array<ChatMessage>`
Returns only client and provider messages from the history (filters out system/internal messages).

## Data Types

### ChatMessage
```typescript
class ChatMessage {
    source: ChatMessageSource;      // Source of the message
    msg: string;                   // Message content
    metadata: Record<string, any>; // Additional metadata
}
```

### ChatMessageSource
```typescript
enum ChatMessageSource {
    CLIENT = 'client',       // User messages
    PROVIDER = 'provider',   // Model responses
    SYSTEM = 'system',       // System notifications
    INTERNAL = 'internal'    // Internal/debug messages
}
```

### ModelInfo
```typescript
class ModelInfo {
    id: string;       // Unique model identifier
    name: string;     // Display name
    provider: string; // Provider name (e.g., "OpenAI")
    apiType: string;  // API type identifier
}
```

## Simple Example

Here's a basic script that adds a timestamp to each user message:

```typescript
/// <reference path="../chat_scripting_api.ts" />

function onUserPrompt(userPrompt: string): void {
    (async () => {
        // Add a system message showing the extension is active
        chatSystemMessage('Extension: Timestamp Logger');
        
        // Create the timestamped message
        const timestamp = new Date().toLocaleTimeString();
        const timestampedPrompt = `[${timestamp}] ${userPrompt}`;
        
        // Add the timestamped message to chat
        const userMessage = new ChatMessage(
            ChatMessageSource.CLIENT, 
            timestampedPrompt, 
            { originalPrompt: userPrompt, timestamp: timestamp }
        );
        addChatMessage(userMessage);
        
        // Send to the first selected model
        const models = getUserSelectedModels();
        if (models.length > 0) {
            const response = await sendMessagesToModel(
                [userMessage], 
                models[0].id, 
                null
            );
            addChatMessage(response);
        } else {
            chatSystemMessage('No model selected!');
        }
    })();
}
```

## Advanced Examples

### Prompt Enhancement
The `improver.ts` extension demonstrates enhancing user prompts before sending them to the selected model:

```typescript
function onUserPrompt(userPrompt: string): void {
    (async () => {
        // Use Claude to improve the prompt
        const improvementMessage = new ChatMessage(
            ChatMessageSource.CLIENT,
            `Improve this prompt to be more specific and clear: ${userPrompt}`,
            {}
        );
        
        const improvedResponse = await chatSendToModel(
            [improvementMessage], 
            'claude-3-5-sonnet-latest'
        );
        
        // Send the improved prompt to the user's selected model
        const userMessage = new ChatMessage(
            ChatMessageSource.CLIENT, 
            improvedResponse.msg.trim(), 
            {}
        );
        addChatMessage(userMessage);
        
        const modelId = getUserSelectedModels()[0].id;
        const finalResponse = await sendMessagesToModel([userMessage], modelId, null);
        addChatMessage(finalResponse);
    })();
}
```

### Multi-Model Interaction
The `party_mode.ts` extension shows how to query multiple models sequentially:

```typescript
function onUserPrompt(userPrompt: string): void {
    (async () => {
        chatSystemMessage('Extension: Party mode invoked');
        chatClientMessage(userPrompt);
        
        // Send to each selected model in sequence
        for (const model of getUserSelectedModels()) {
            const conversation = getConversation();
            const response = await chatSendToModel(conversation, model.id);
            addChatMessage(response);
        }
    })();
}
```

## Best Practices

1. **Always use async/await**: Wrap your logic in an async IIFE to handle promises properly
2. **Error handling**: Use try-catch blocks for robust error handling
3. **Type safety**: Include the TypeScript reference path for IDE support
4. **User feedback**: Use system messages to inform users about script actions
5. **Respect user selection**: Default to user-selected models when appropriate

## Loading Scripts

Scripts can be loaded in two ways:

1. **From URL**: 
   ```dart
   ChatScripting.init(
     url: "https://example.com/my-script.js",
     // ... other parameters
   );
   ```

2. **Direct string**:
   ```dart
   ChatScripting.init(
     script: "function onUserPrompt(userPrompt) { ... }",
     // ... other parameters
   );
   ```

Enable debug mode for development to automatically reload scripts before each execution:
```dart
ChatScripting.init(
  debugMode: true,
  // ... other parameters
);
```

## Security Considerations

- Scripts run in the browser context with access to the chat API
- Scripts cannot access local files or make arbitrary network requests
- Always review scripts from untrusted sources before loading
- Use HTTPS URLs for loading remote scripts