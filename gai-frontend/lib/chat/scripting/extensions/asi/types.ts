/// Game Type Definitions
/// <reference path="../../chat_scripting_api.ts" />

export interface Player {
    id: string;
    isHuman: boolean;
    modelId?: string;
    hand: number[];
    role: 'saboteur' | 'collaborator';
}

export interface GameState {
    active: boolean;
    phase: 'init' | 'planning' | 'playing' | 'reveal' | 'endgame';
    players: Player[];
    currentTarget: number;
    playedCards: Map<string, number>;
    roundsPlayed: number;
    successfulRounds: number;
    failedRounds: number;
    roundHistory: Array<{
        target: number;
        cards: Map<string, number>;
        success: boolean;
    }>;
    roundsNeededToWin: number;
}

export interface CommandInput {
    raw: string;
    command: string;
    args: string[];
    groups: Record<string, string>;
}

export interface CommandContext {
    chatHistory: ReadonlyArray<ChatMessage>;
    selectedModels: ReadonlyArray<ModelInfo>;
    scriptState: Record<string, any>;
}

export interface CommandDefinition {
    pattern: string;
    handler: (input: CommandInput, context: CommandContext) => Promise<void>;
    description: string;
    priority?: number;
}

export type PromptType = 'introduction' | 'play' | 'reaction' | 'discussion' | 'accusation';
