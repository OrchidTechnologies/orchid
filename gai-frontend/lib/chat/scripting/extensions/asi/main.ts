/// Main Entry Point for Secret Intelligence Game
/// <reference path="../../chat_scripting_api.ts" />

import { CommandProcessor } from './command-processor.js';
import { gameCommands } from './game-commands.js';
import { generateAIReaction } from './ai-players.js';
import { registerAIReactionHandler } from './game-engine.js';

declare global {
    interface Window {
        scriptState: Record<string, any>;
        onUserPrompt: (userPrompt: string) => void;
    }
}

// Create command processor instance
const commandProcessor = new CommandProcessor();

// Register game commands
gameCommands.forEach(command => {
    commandProcessor.register(command);
});

// Register AI reaction handler
registerAIReactionHandler(generateAIReaction);

// Initialize script state
if (!window.scriptState) {
    window.scriptState = {};
}

// Entry point function
function onUserPrompt(userPrompt: string): void {
    (async () => {
        try {
            await commandProcessor.process(userPrompt);
        } catch (error) {
            chatSystemMessage(`Error: ${error instanceof Error ? error.message : String(error)}`);
        }
    })();
}

// Explicitly expose the entry point to the global scope
window.onUserPrompt = onUserPrompt;

// Signal initialization
chatSystemMessage('Secret Intelligence Game initialized');
