/// Command Layer Implementation
/// <reference path="../chat_scripting_api.ts" />

// Types
interface CommandContext {
  chatHistory: ReadonlyArray<ChatMessage>;
  selectedModels: ReadonlyArray<ModelInfo>;
  scriptState: Record<string, any>;
}

interface CommandDefinition {
  pattern: string;
  handler: (input: CommandInput, context: CommandContext) => Promise<void>;
  description: string;
  priority?: number;
}

interface CommandInput {
  raw: string;
  command: string;
  args: string[];
  groups: Record<string, string>;
}

// Global command processor instance
const commandProcessor = new class {
  private commands: CommandDefinition[] = [];
  private fallbackHandler: ((input: string, context: CommandContext) => Promise<void>) | null = null;
  private scriptState: Record<string, any> = {};

  register(command: CommandDefinition) {
    const priority = command.priority || 0;
    const index = this.commands.findIndex(cmd => (cmd.priority || 0) < priority);
    if (index === -1) {
      this.commands.push(command);
    } else {
      this.commands.splice(index, 0, command);
    }
  }

  unregister(pattern: string) {
    this.commands = this.commands.filter(cmd => cmd.pattern !== pattern);
  }

  setFallback(handler: (input: string, context: CommandContext) => Promise<void>) {
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
        } catch (error) {
          const errorMsg = `Command execution failed: ${error.message}`;
          chatSystemMessage(errorMsg);
          throw new Error(errorMsg);
        }
        return;
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
}();

// Register built-in commands
commandProcessor.register({
  pattern: '/help',
  handler: async () => {
    chatSystemMessage(commandProcessor.getHelp());
  },
  description: 'Show available commands'
});

// Register example commands
commandProcessor.register({
  pattern: '/party',
  description: 'Send message to all selected models',
  handler: async (input: CommandInput) => {
    chatSystemMessage('Party mode activated!');
    const userPrompt = input.args.join(' ');
    chatClientMessage(userPrompt);

    for (const model of getUserSelectedModels()) {
      const filteredMessages = getConversation();
      const response = await chatSendToModel(filteredMessages, model.id);
      addChatMessage(response);
    }
  }
});

commandProcessor.register({
  pattern: '/improve',
  description: 'Improve prompt using Claude before sending',
  handler: async (input: CommandInput) => {
    const userPrompt = input.args.join(' ');
    chatSystemMessage('Improving prompt...');

    const improvementMessage = new ChatMessage(
      ChatMessageSource.CLIENT,
      `You are a prompt improvement assistant. Your task is to improve the following prompt to be ` +
      `more specific, clear, and effective. Maintain the original intent but make it more detailed ` +
      `and precise. Respond with only the improved prompt, no explanations: ` +
      `{BEGIN_PROMPT}${userPrompt}{END_PROMPT}`,
      {}
    );

    const improvedResponse = await chatSendToModel([improvementMessage], 'claude-3-5-sonnet-latest');
    const improvedPrompt = improvedResponse.msg.trim();

    chatSystemMessage(`Original prompt: ${userPrompt}`);
    chatInternalMessage(`Improved prompt: ${improvedPrompt}`);

    const userMessage = new ChatMessage(ChatMessageSource.CLIENT, improvedPrompt, {});
    addChatMessage(userMessage);

    const selectedModels = getUserSelectedModels();
    if (selectedModels.length > 0) {
      const modelId = selectedModels[0].id;
      addChatMessage(await sendMessagesToModel([userMessage], modelId, null));
    }
  }
});

// Set default fallback
commandProcessor.setFallback(async (input: string) => {
  const selectedModels = getUserSelectedModels();
  if (selectedModels.length === 0) {
    chatSystemMessage('No models selected');
    return;
  }

  const userMessage = new ChatMessage(ChatMessageSource.CLIENT, input, {});
  addChatMessage(userMessage);
  
  const response = await chatSendToModel([userMessage], selectedModels[0].id);
  if (response) {
    addChatMessage(response);
  }
});

// Entry point implementation
function onUserPrompt(userPrompt: string): void {
  (async () => {
    try {
      await commandProcessor.process(userPrompt);
    } catch (error) {
      console.error('Error processing command:', error);
      chatSystemMessage(error.message);
    }
  })();
}

// Signal that the script is loaded
chatSystemMessage('Command processor initialized');
