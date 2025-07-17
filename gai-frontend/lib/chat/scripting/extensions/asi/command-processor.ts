/// Command Processing System
/// <reference path="../../chat_scripting_api.ts" />

import { CommandInput, CommandContext, CommandDefinition } from './types';

export class CommandProcessor {
    private commands: CommandDefinition[] = [];
    private fallbackHandler: ((input: string, context: CommandContext) => Promise<void>) | null = null;
    private scriptState: Record<string, any> = {};

    register(command: CommandDefinition): void {
        const priority = command.priority || 0;
        const index = this.commands.findIndex(cmd => (cmd.priority || 0) < priority);
        if (index === -1) {
            this.commands.push(command);
        } else {
            this.commands.splice(index, 0, command);
        }
    }

    unregister(pattern: string): void {
        this.commands = this.commands.filter(cmd => cmd.pattern !== pattern);
    }

    setFallback(handler: (input: string, context: CommandContext) => Promise<void>): void {
        this.fallbackHandler = handler;
    }

    private parseCommand(input: string): CommandInput | null {
        for (const command of this.commands) {
            if (command.pattern.startsWith('/')) {
                const parts = input.split(' ');
                if (parts[0] === command.pattern) {
                    return {
                        raw: input,
                        command: parts[0],
                        args: parts.slice(1),
                        groups: {}
                    };
                }
            } else {
                try {
                    const regex = new RegExp(command.pattern);
                    const match = input.match(regex);
                    if (match) {
                        return {
                            raw: input,
                            command: match[0],
                            args: match.slice(1),
                            groups: match.groups || {}
                        };
                    }
                } catch (e) {
                    console.error(`Invalid regex pattern: ${command.pattern}`);
                }
            }
        }
        return null;
    }

    async process(input: string): Promise<void> {
        const context: CommandContext = {
            chatHistory: getChatHistory(),
            selectedModels: getUserSelectedModels(),
            scriptState: this.scriptState
        };

        const parsed = this.parseCommand(input);
        
        if (parsed) {
            const command = this.commands.find(cmd => 
                cmd.pattern.startsWith('/') ? cmd.pattern === parsed.command :
                input.match(new RegExp(cmd.pattern))
            );
            
            if (command) {
                try {
                    await command.handler(parsed, context);
                    return;
                } catch (error) {
                    const errorMsg = `Command execution failed: ${error instanceof Error ? error.message : String(error)}`;
                    chatSystemMessage(errorMsg);
                    throw new Error(errorMsg);
                }
            }
        }

        if (this.fallbackHandler) {
            await this.fallbackHandler(input, context);
        } else {
            throw new Error('No matching command or fallback handler');
        }
    }

    getHelp(): string {
        return this.commands
            .map(cmd => `${cmd.pattern}: ${cmd.description}`)
            .join('\n');
    }
}
