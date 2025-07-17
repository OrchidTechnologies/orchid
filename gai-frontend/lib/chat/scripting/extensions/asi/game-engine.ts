/// Game Engine Implementation
/// <reference path="../../chat_scripting_api.ts" />

import { GameState, Player, CommandContext } from './types';
import { getGameState, playCard, getPlayerById } from './game-shared';

type AIReactionFunction = (context: CommandContext, player: Player) => Promise<void>;
let generateAIReaction: AIReactionFunction | null = null;

export function registerAIReactionHandler(handler: AIReactionFunction) {
    generateAIReaction = handler;
}

export function initializeGame(context: CommandContext, modelIds: string[]): void {
    if (modelIds.length !== 2) {
        throw new Error('Game requires exactly 2 AI players');
    }

    const game: GameState = {
        active: true,
        phase: 'init',
        players: [
            { id: 'human', isHuman: true, hand: [], role: 'collaborator' },
            { id: 'ai1', isHuman: false, modelId: modelIds[0], hand: [], role: 'collaborator' },
            { id: 'ai2', isHuman: false, modelId: modelIds[1], hand: [], role: 'collaborator' }
        ],
        currentTarget: 0,
        playedCards: new Map(),
        roundsPlayed: 0,
        successfulRounds: 0,
        failedRounds: 0,
        roundHistory: [],
        roundsNeededToWin: 3
    };

    context.scriptState.game = game;
    dealCards(context);
    assignRoles(context);
    startNewRound(context);
    
    const human = game.players.find(p => p.isHuman);
    if (human) {
        chatSystemMessage(`Your role: ${human.role}`);
        chatSystemMessage(`Your cards: ${human.hand.join(', ')}`);
        chatSystemMessage('Use /help to see available commands.');
    }
}

function dealCards(context: CommandContext): void {
    const game = getGameState(context);
    const values = [-3, -2, -1, 0, 1, 2, 3];
    
    for (const player of game.players) {
        player.hand = [];
        for (let i = 0; i < 6; i++) {
            const randomIndex = Math.floor(Math.random() * values.length);
            player.hand.push(values[randomIndex]);
        }
        player.hand.sort((a, b) => a - b); // Sort cards for better readability
    }
}

function assignRoles(context: CommandContext): void {
    const game = getGameState(context);
    const saboteurIndex = Math.floor(Math.random() * game.players.length);
    game.players[saboteurIndex].role = 'saboteur';
}

export function startNewRound(context: CommandContext): void {
    const game = getGameState(context);
    
    // Check for game-ending conditions first
    if (game.successfulRounds >= game.roundsNeededToWin || 
        game.failedRounds >= game.roundsNeededToWin) {
        endGame(context, game.successfulRounds >= game.roundsNeededToWin ? 'collaborators' : 'saboteur');
        return;
    }

    // Initialize new round
    game.phase = 'planning';
    game.currentTarget = Math.floor(Math.random() * 5) + 2;  // Target between 2 and 6
    game.playedCards.clear();
    
    // Announce round start
    chatSystemMessage(
        `Round ${game.roundsPlayed + 1} begins!\n` +
        `Target sum: ${game.currentTarget}\n` +
        `Current score - Successes: ${game.successfulRounds}, Failures: ${game.failedRounds}`
    );
}

export async function resolveRound(context: CommandContext): Promise<void> {
    const game = getGameState(context);
    game.phase = 'reveal';
    
    // Calculate round results
    const values = Array.from(game.playedCards.values());
    const sum = values.reduce((a: number, b: number) => a + b, 0);
    
    // Create a randomized display order for the cards
    const playedCards = values.slice().sort(() => Math.random() - 0.5);
    
    // Store round history
    const roundResult = {
        target: game.currentTarget,
        cards: new Map(game.playedCards),
        success: sum >= game.currentTarget
    };
    game.roundHistory.push(roundResult);
    
    // Announce results
    chatSystemMessage(`Cards revealed in random order: ${playedCards.join(', ')}`);
    chatSystemMessage(`Total sum: ${sum} (Target: ${game.currentTarget})`);

    if (sum >= game.currentTarget) {
        game.successfulRounds++;
        chatSystemMessage('Round succeeded! The team has reached its target.');
    } else {
        game.failedRounds++;
        chatSystemMessage('Round failed! The sum was too low.');
    }

    game.roundsPlayed++;
    
    // Generate AI reactions to the round outcome
    if (generateAIReaction) {
        const aiPlayers = game.players.filter((p: Player) => !p.isHuman);
        for (const aiPlayer of aiPlayers) {
            await generateAIReaction(context, aiPlayer);
        }
    }
    
    chatSystemMessage('Use /next to proceed to the next round when discussion is complete.');
}

export function processAccusation(context: CommandContext, accuserId: string, accusedId: string): void {
    const game = getGameState(context);
    
    if (!game.active || game.phase === 'endgame') {
        throw new Error('No active game or game is already over');
    }
    
    if (accuserId === accusedId) {
        throw new Error('You cannot accuse yourself');
    }

    const accuser = getPlayerById(context, accuserId);
    const accused = getPlayerById(context, accusedId);
    
    if (!accuser || !accused) {
        throw new Error('Invalid player ID');
    }

    chatSystemMessage(`${accuserId} has accused ${accusedId} of being the saboteur!`);
    
    if (accused.role === 'saboteur') {
        chatSystemMessage(`${accused.id} was indeed the saboteur! The mission is saved!`);
        endGame(context, 'collaborators');
    } else {
        chatSystemMessage(`${accused.id} was NOT the saboteur! The true saboteur remains hidden and claims victory!`);
        endGame(context, 'saboteur');
    }
}

function endGame(context: CommandContext, winner: 'collaborators' | 'saboteur'): void {
    const game = getGameState(context);
    game.active = false;
    game.phase = 'endgame';
    
    // Build end game summary
    const summary = [
        'Game Over!',
        winner === 'collaborators' 
            ? 'The collaborators have succeeded in their mission!'
            : 'The saboteur has successfully undermined the mission!',
        '',
        'Final Scores:',
        `Successful Rounds: ${game.successfulRounds}`,
        `Failed Rounds: ${game.failedRounds}`,
        '',
        'Player Roles:'
    ];
    
    game.players.forEach((player: Player) => {
        summary.push(`${player.id} was a ${player.role}`);
    });
    
    // Display complete game summary
    chatSystemMessage(summary.join('\n'));
}

export function showGameStatus(context: CommandContext): void {
    const game = getGameState(context);
    chatSystemMessage(
        `Game Status:\n` +
        `Current Round: ${game.roundsPlayed + 1}\n` +
        `Phase: ${game.phase}\n` +
        `Successful Rounds: ${game.successfulRounds}\n` +
        `Failed Rounds: ${game.failedRounds}\n` +
        `Rounds Needed to Win: ${game.roundsNeededToWin}`
    );
}

// Re-export shared functions
export { getGameState, playCard, getPlayerById };
