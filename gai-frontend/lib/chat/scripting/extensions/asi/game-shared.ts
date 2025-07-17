/// Shared game functionality
/// <reference path="../../chat_scripting_api.ts" />

import { GameState, Player, CommandContext } from './types';

export function getGameState(context: CommandContext): GameState {
    if (!context.scriptState.game) {
        context.scriptState.game = {
            active: false,
            phase: 'init',
            players: [],
            currentTarget: 0,
            playedCards: new Map<string, number>(),
            roundsPlayed: 0,
            successfulRounds: 0,
            failedRounds: 0,
            roundsNeededToWin: 3
        };
    }
    return context.scriptState.game;
}

export function playCard(context: CommandContext, playerId: string, card: number): void {
    const game = getGameState(context);
    const player = game.players.find((p: Player) => p.id === playerId);
    if (!player) return;

    game.playedCards.set(playerId, card);
    const cardIndex = player.hand.indexOf(card);
    player.hand.splice(cardIndex, 1);

    chatSystemMessage(`${playerId} has played a card.`);
    
    if (player.isHuman) {
        chatSystemMessage(`Your updated hand: ${player.hand.join(', ')}`);
    }
}

export function getPlayerById(context: CommandContext, playerId: string): Player | undefined {
    const game = getGameState(context);
    return game.players.find((p: Player) => p.id === playerId);
}

export function isGameWon(game: GameState): false | 'collaborators' | 'saboteur' {
    if (game.successfulRounds >= game.roundsNeededToWin) {
        return 'collaborators';
    }
    if (game.failedRounds >= game.roundsNeededToWin) {
        return 'saboteur';
    }
    return false;
}
