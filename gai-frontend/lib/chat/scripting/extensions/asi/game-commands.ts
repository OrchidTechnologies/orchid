/// Game Commands Implementation
/// <reference path="../../chat_scripting_api.ts" />

import { CommandDefinition, CommandInput, CommandContext, Player } from './types';
import {
    getGameState,
    initializeGame,
    playCard,
    resolveRound,
    showGameStatus,
    getPlayerById,
    startNewRound,
    processAccusation
} from './game-engine';
import { handleAITurns, handleAIDiscussion } from './ai-players';

const createGameCommands = (): CommandDefinition[] => [
    {
        pattern: '/start',
        handler: async (input: CommandInput, context: CommandContext) => {
            const game = getGameState(context);
            if (game.active) {
                chatSystemMessage('A game is already in progress.');
                return;
            }

            const selectedModels = getUserSelectedModels();
            if (selectedModels.length < 2) {
                chatSystemMessage('Please select at least 2 AI models to play with.');
                return;
            }

            const modelIds = selectedModels.slice(0, 2).map(model => model.id);
            initializeGame(context, modelIds);
            chatSystemMessage('Game started! Use /help to see available commands.');
            showGameStatus(context);
        },
        description: 'Start a new game',
        priority: 1
    },
    
    {
        pattern: '/hand',
        handler: async (input: CommandInput, context: CommandContext) => {
            const game = getGameState(context);
            if (!game.active) {
                chatSystemMessage('No active game. Use /start to begin a new game.');
                return;
            }

            const human = getPlayerById(context, 'human');
            if (!human) return;

            chatSystemMessage(`Your role: ${human.role}\nYour cards: ${human.hand.join(', ')}`);
        },
        description: 'Show your current hand',
        priority: 1
    },
    
    {
        pattern: '/play',
        handler: async (input: CommandInput, context: CommandContext) => {
            const game = getGameState(context);
            if (!game.active || game.phase !== 'planning') {
                chatSystemMessage('Cannot play a card right now.');
                return;
            }

            if (game.playedCards.has('human')) {
                chatSystemMessage('You have already played a card this round.');
                return;
            }

            const card = parseInt(input.args[0]);
            if (isNaN(card)) {
                chatSystemMessage('Please specify a valid number. Usage: /play <number>');
                return;
            }

            const human = getPlayerById(context, 'human');
            if (!human) return;

            if (!human.hand.includes(card)) {
                chatSystemMessage('You do not have that card.');
                return;
            }

            playCard(context, 'human', card);
            
            // Process AI turns after human plays
            if (game.playedCards.size < game.players.length) {
                await handleAITurns(context);
            }
            
            // Check if all cards are played
            if (game.playedCards.size === game.players.length) {
                await resolveRound(context);
            }
        },
        description: 'Play a card from your hand',
        priority: 1
    },
    
    {
        pattern: '/next',
        handler: async (input: CommandInput, context: CommandContext) => {
            const game = getGameState(context);
            if (!game.active) {
                chatSystemMessage('No active game. Use /start to begin a new game.');
                return;
            }
            
            if (game.phase !== 'reveal') {
                chatSystemMessage('Cannot proceed to next round yet. Finish the current round first.');
                return;
            }
            
            startNewRound(context);
        },
        description: 'Proceed to next round after discussion',
        priority: 1
    },
    
    {
        pattern: '/accuse',
        handler: async (input: CommandInput, context: CommandContext) => {
            const game = getGameState(context);
            if (!game.active) {
                chatSystemMessage('No active game.');
                return;
            }
            
            const accusedId = input.args[0];
            if (!accusedId || !getPlayerById(context, accusedId)) {
                chatSystemMessage('Invalid player ID. Usage: /accuse <player_id> (e.g., /accuse ai1)');
                return;
            }
            
            try {
                processAccusation(context, 'human', accusedId);
            } catch (error) {
                chatSystemMessage(error instanceof Error ? error.message : 'Error processing accusation');
            }
        },
        description: 'Accuse a player of being the saboteur (ends the game immediately)',
        priority: 1
    },
    
    {
        pattern: '/status',
        handler: async (input: CommandInput, context: CommandContext) => {
            const game = getGameState(context);
            if (!game.active) {
                chatSystemMessage('No active game. Use /start to begin a new game.');
                return;
            }
            
            showGameStatus(context);
        },
        description: 'Show current game status',
        priority: 1
    },
    
    {
        pattern: '/help',
        handler: async (input: CommandInput, context: CommandContext) => {
            const commands = [
                '/start - Start a new game',
                '/hand - Show your current hand',
                '/play <number> - Play a card from your hand',
                '/next - Proceed to next round after discussion',
                '/accuse <player_id> - Accuse a player of being the saboteur',
                '/status - Show current game status',
                '/help - Show this help message'
            ];
            
            chatSystemMessage('Available commands:\n' + commands.join('\n'));
        },
        description: 'Show help message',
        priority: 1
    },
    
    {
        pattern: '.*',
        handler: async (input: CommandInput, context: CommandContext) => {
            const game = getGameState(context);
            if (!game.active) {
                chatSystemMessage('No game in progress. Use /start to begin a new game.');
                return;
            }

            // Ignore command-like messages that don't match other patterns
            if (input.raw.startsWith('/')) {
                chatSystemMessage('Unknown command. Use /help to see available commands.');
                return;
            }
            
            chatClientMessage(input.raw);
            
            // Handle discussion during both planning and reveal phases
            if (game.phase === 'planning' || game.phase === 'reveal') {
                const aiPlayers = game.players.filter((p: Player) => !p.isHuman);
                for (const aiPlayer of aiPlayers) {
                    await handleAIDiscussion(context, aiPlayer, input.raw);
                }
            }
        },
        description: 'Chat during the game',
        priority: 0
    }
];

export const gameCommands = createGameCommands();
