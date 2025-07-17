/// AI Player Interaction System
/// <reference path="../../chat_scripting_api.ts" />

import { Player, GameState, CommandContext } from './types';
import { getGameState, playCard, getPlayerById } from './game-shared';
import { registerAIReactionHandler, processAccusation } from './game-engine';

type PromptType = 'introduction' | 'play' | 'reaction' | 'discussion' | 'accusation';
const PROMPT_TYPES = ['introduction', 'play', 'reaction', 'discussion', 'accusation'] as const;

export async function handleAITurns(context: CommandContext): Promise<void> {
    const game = getGameState(context);
    const aiPlayers = game.players.filter((p: Player) => !p.isHuman && !game.playedCards.has(p.id));
    
    for (const aiPlayer of aiPlayers) {
        await processAITurn(context, aiPlayer);
        
        // Consider making an accusation after playing if enough rounds have passed
        if (game.roundsPlayed >= 2) {
            await considerAccusation(context, aiPlayer);
        }
    }
}

function createInitialContext(player: Player): string {
    const roleDescription = player.role === 'saboteur'
        ? 'Your goal is to make rounds fail while appearing helpful. You must never reveal your role or strategy.'
        : 'Your goal is to help the team reach target numbers while watching for saboteurs. You must never reveal your role.';

    return `You are playing as ${player.id} in a social deduction card game. ${roleDescription}

Key Instructions:
- ONLY respond with what you would say out loud to other players
- Never include internal thoughts, strategy notes, or commentary
- Never reveal whether you are a collaborator or saboteur
- Stay in character at all times
- Keep responses concise and natural

Remember that everything you say will be heard by all players.`;
}

function formatGameState(game: GameState, player: Player): string {
    const currentSum = Array.from(game.playedCards.values()).reduce((a, b) => a + b, 0);
    const roundOutcome = game.phase === 'reveal' 
        ? `\nRound Outcome: ${currentSum >= game.currentTarget ? 'SUCCESS' : 'FAILED'}`
        : '';
        
    const playedCardsStr = Array.from(game.playedCards.entries())
        .map(([id, card]) => `${id}: ${card}`).join(', ');

    return `Current Game State:
Target: ${game.currentTarget}
Round: ${game.roundsPlayed + 1}
Success/Fail: ${game.successfulRounds}/${game.failedRounds}
Your Hand: ${player.hand.join(', ')}
Cards Played: ${playedCardsStr || 'None'}
Current Sum: ${currentSum}
Players to Play: ${game.players.length - game.playedCards.size}${roundOutcome}`;
}

function constructPromptMessages(game: GameState, player: Player, promptType: PromptType): ChatMessage[] {
    const messages: ChatMessage[] = [
        new ChatMessage(
            ChatMessageSource.CLIENT,
            createInitialContext(player),
            {}
        )
    ];

    // Get conversation history since the last round start
    const lastRoundStart = getChatHistory()
        .findIndex(msg => 
            msg.source === ChatMessageSource.SYSTEM && 
            (msg.msg.includes("Round begins!") || msg.msg.includes("Game started!"))
        );

    // Add relevant discussion messages
    const discussionMessages = getChatHistory()
        .slice(lastRoundStart + 1)
        .filter(msg => 
            (msg.source === ChatMessageSource.PROVIDER || 
             msg.source === ChatMessageSource.CLIENT) &&
            !msg.msg.includes("Error") &&
            !msg.msg.includes("Retrying") &&
            !msg.msg.includes("Current Game State:")
        )
        .map(msg => new ChatMessage(
            msg.source,
            msg.msg.includes(':') ? msg.msg.split(':').slice(1).join(':').trim() : msg.msg,
            {}
        ));

    messages.push(...discussionMessages);

    // Add current game state
    messages.push(new ChatMessage(
        ChatMessageSource.CLIENT,
        formatGameState(game, player),
        {}
    ));

    if (promptType === 'reaction') {
        const currentSum = Array.from(game.playedCards.values()).reduce((a, b) => a + b, 0);
        const roundResult = currentSum >= game.currentTarget ? 'SUCCESS' : 'FAILED';
        messages.push(new ChatMessage(
            ChatMessageSource.CLIENT,
            `The round has ${roundResult === 'SUCCESS' ? 'succeeded' : 'failed'}! ` +
            `Final sum was ${currentSum} (Target: ${game.currentTarget}).\n\n` +
            'Comment on this outcome with ONE brief response.\n\n' +
            'Important:\n' +
            '- Speak only as your character would to other players\n' +
            '- Keep your response natural and concise\n' +
            '- Never reveal your true role',
            {}
        ));
        return messages;
    }

    // Add appropriate prompt based on type
    const promptText = getPromptForType(promptType, game, player);
    if (promptText) {
        messages.push(new ChatMessage(
            ChatMessageSource.CLIENT,
            promptText,
            {}
        ));
    }

    return messages;
}

function getPromptForType(promptType: PromptType, game: GameState, player: Player): string {
    switch (promptType) {
        case 'introduction':
            return 'Introduce yourself to the other players. Do not reveal your role directly, but express your intentions for the game. Be brief but engaging.';

        case 'play':
            return `Choose a card to play from your hand: ${player.hand.join(', ')}\n\n` +
                   'Important:\n' +
                   '- Respond ONLY with the numerical value you wish to play\n' +
                   '- No explanation or commentary\n' +
                   '- No roleplay or additional text';

        case 'discussion':
            const phaseContext = game.phase === 'planning' 
                ? 'Players are discussing their choices before playing cards.'
                : 'Players are discussing the revealed cards and round outcome.';
            
            return `${phaseContext}\n\n` +
                   'Respond to the ongoing discussion with what you would say to the other players.\n\n' +
                   'Important:\n' +
                   '- Speak only in character, as if at a game table\n' +
                   '- No internal thoughts or commentary\n' +
                   '- Keep responses natural and brief\n' +
                   '- Never reveal your true role';

        case 'accusation':
            return createAccusationPrompt(game, player);

        default:
            return '';
    }
}

function createAccusationPrompt(game: GameState, player: Player): string {
    const roundHistory = game.roundHistory || [];
    const recentRounds = roundHistory.slice(-3);
    
    const recentRoundsSummary = recentRounds.map((r, i) => {
        const sum = Array.from(r.cards.values()).reduce((a, b) => a + b, 0);
        return `Round ${game.roundsPlayed - recentRounds.length + i + 1}: ` +
               `${r.success ? 'Success' : 'Fail'} ` +
               `(Target: ${r.target}, Sum: ${sum}, Cards: ${Array.from(r.cards.entries())
                   .map(([id, card]) => `${id}=${card}`).join(' ')})`;
    }).join('\n');
    
    return `Based on the game history, decide if you want to accuse someone of being the saboteur.

Game History:
- Rounds played: ${game.roundsPlayed}
- Successful/Failed rounds: ${game.successfulRounds}/${game.failedRounds}
Round details:
${recentRoundsSummary}

To accuse someone, respond with "accuse <player_id>". Otherwise, respond with "continue".

Critical Guidelines for Accusations:
1. Only accuse if you have VERY STRONG evidence of sabotage
2. Wrong accusations lead to immediate game loss
3. Look for clear patterns across multiple rounds
4. Consider all possibilities and explanations
5. When in doubt, choose "continue"

Remember: A wrong accusation means instant defeat. Be absolutely certain before making an accusation.`;
}

async function processAITurn(context: CommandContext, player: Player): Promise<void> {
    const game = getGameState(context);
    const messages = constructPromptMessages(game, player, 'play');

    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
        try {
            const response = await chatSendToModel(messages, player.modelId!);

            if (!response) {
                throw new Error('No response received from AI player');
            }

            const decision = parseAIResponse(response.msg);
            if (decision !== null && player.hand.includes(decision)) {
                playCard(context, player.id, decision);
                return;
            }

            attempts++;
            if (attempts < maxAttempts) {
                chatSystemMessage(`${player.id} made an invalid choice. Retrying...`);
            }
        } catch (error) {
            attempts++;
            if (attempts < maxAttempts) {
                chatSystemMessage(`${player.id} encountered an error. Retrying...`);
            }
        }
    }

    // Fall back to random card if all attempts fail
    const randomCard = player.hand[Math.floor(Math.random() * player.hand.length)];
    playCard(context, player.id, randomCard);
    chatSystemMessage(`${player.id} failed to make a valid choice after ${maxAttempts} attempts. Playing a random card.`);
}

async function considerAccusation(context: CommandContext, player: Player): Promise<void> {
    const game = getGameState(context);
    const messages = constructPromptMessages(game, player, 'accusation');
    
    try {
        const response = await chatSendToModel(messages, player.modelId!);
        if (!response) return;

        const accusationMatch = response.msg.match(/accuse (.+)/i);
        if (accusationMatch) {
            const accusedId = accusationMatch[1].trim();
            if (accusedId && getPlayerById(context, accusedId)) {
                processAccusation(context, player.id, accusedId);
            }
        }
    } catch (error) {
        // Silently handle errors - no accusation will be made
    }
}

function parseAIResponse(response: string): number | null {
    const cleaned = response.trim().replace(/[^-\d]/g, '');
    const number = parseInt(cleaned);
    return isNaN(number) ? null : number;
}

export async function generateAIReaction(context: CommandContext, player: Player): Promise<void> {
    const game = getGameState(context);
    const messages = constructPromptMessages(game, player, 'reaction');

    try {
        const response = await chatSendToModel(messages, player.modelId!);
        if (response) {
            chatProviderMessage(`${player.id}: ${response.msg}`);
        }
    } catch (error) {
        chatSystemMessage(`${player.id} was unable to comment on the round.`);
    }
}

export async function handleAIDiscussion(context: CommandContext, player: Player, userMessage: string): Promise<void> {
    const game = getGameState(context);
    const messages = constructPromptMessages(game, player, 'discussion');

    // Add the user's message as the last message before the prompt
    messages.splice(messages.length - 1, 0, new ChatMessage(
        ChatMessageSource.CLIENT,
        userMessage,
        {}
    ));

    try {
        const response = await chatSendToModel(messages, player.modelId!);
        if (response) {
            chatProviderMessage(`${player.id}: ${response.msg}`);
        }
    } catch (error) {
        chatSystemMessage(`${player.id} was unable to respond to the discussion.`);
    }
}
