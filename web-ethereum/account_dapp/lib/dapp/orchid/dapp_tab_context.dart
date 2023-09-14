import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';

mixin DappTabWalletContext {
  bool txPending = false;

  OrchidWeb3Context? get web3Context;

  OrchidWallet? get wallet => web3Context?.wallet;

  // The wallet balance of the configured token type or null if no tokens known
  Token? get walletBalance => wallet?.balance;

  Token? walletBalanceOf(TokenType token) => wallet?.balanceOf(token);

  // The native token type of the chain or TOK as a default
  TokenType get tokenType => web3Context?.chain.nativeCurrency ?? Tokens.TOK;
}

mixin DappTabPotContext {
  LotteryPot? get pot;

  EthereumAddress? get signer;

  bool get connected => pot != null && signer != null;
}
