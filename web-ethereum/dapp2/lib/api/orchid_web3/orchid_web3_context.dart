import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';

import '../orchid_log_api.dart';

/// This class abstracts over the flutter_web3 ethereum and wallet connect providers
/// and provides access to chain and wallet info for the current connection.
class OrchidWeb3Context {
  /// The web3 provider, either wrapping an Ethereum provider or a Wallet Connect provider.
  final Web3Provider web3;

  final Chain chain;
  final EthereumAddress walletAddress;

  /// If the web3 provider wraps ethereum this is the underlying provider.
  final Ethereum ethereumProvider;

  /// If the web3 provider wraps wallet connect this is the underlying provider.
  final WalletConnectProvider walletConnectProvider;

  // Wallet
  OrchidWallet wallet;
  OrchidWallet _lastWallet;
  Timer _pollWalletTimer;
  Duration _pollWalletPeriod = Duration(seconds: 5);
  VoidCallback _walletUpdateListener;

  OrchidWeb3Context._({
    this.web3,
    this.chain,
    this.walletAddress,
    Ethereum ethereumProvider,
    WalletConnectProvider walletConnectProvider,
  })  : this.ethereumProvider = ethereumProvider,
        this.walletConnectProvider = walletConnectProvider {
    _startPollingWallet();
  }

  void _startPollingWallet() {
    _pollWalletTimer = Timer.periodic(_pollWalletPeriod, _pollWallet);
    _pollWallet(null);
  }

  static Future<OrchidWeb3Context> fromEthereum(Ethereum ethereum) async {
    var accounts = await ethereum.requestAccount(); // requestAccounts
    var walletAddress =
        accounts.isNotEmpty ? EthereumAddress.from(accounts.first) : null;

    var context = OrchidWeb3Context._(
      web3: Web3Provider.fromEthereum(ethereum),
      ethereumProvider: ethereum,
      walletConnectProvider: null,
      chain: Chains.chainFor(await ethereum.getChainId()),
      walletAddress: walletAddress,
    );

    return context;
  }

  static Future<OrchidWeb3Context> fromWalletConnect(
      WalletConnectProvider walletConnectProvider) async {
    var walletAddress = walletConnectProvider.accounts.isNotEmpty
        ? EthereumAddress.from(walletConnectProvider.accounts.first)
        : null;

    var context = OrchidWeb3Context._(
      web3: Web3Provider.fromWalletConnect(walletConnectProvider),
      ethereumProvider: null,
      walletConnectProvider: walletConnectProvider,
      chain: Chains.chainFor(int.parse(walletConnectProvider.chainId)),
      walletAddress: walletAddress,
    );
    return context;
  }

  Future<OrchidWallet> getWallet() async {
    var nativeCurrency = chain.nativeCurrency;
    var nativeBalance =
        nativeCurrency.fromInt(await web3.getBalance(walletAddress.toString()));
    return OrchidWallet(this, {nativeCurrency: nativeBalance});
  }

  void onAccountsChanged(void Function(List<String> accounts) listener) {
    if (ethereumProvider != null) {
      ethereumProvider.onAccountsChanged(listener);
    } else {
      walletConnectProvider.onAccountsChanged(listener);
    }
  }

  void onChainChanged(void Function(int chainId) listener) {
    if (ethereumProvider != null) {
      ethereumProvider.onChainChanged(listener);
    } else {
      walletConnectProvider.onChainChanged(listener);
    }
  }

  void onConnect(void Function() listener) {
    if (ethereumProvider != null) {
      ethereumProvider.onConnect((_) => listener());
    } else {
      walletConnectProvider.onConnect(listener);
    }
  }

  void onDisconnect(void Function() listener) {
    if (ethereumProvider != null) {
      ethereumProvider.onDisconnect((error) => listener());
    } else {
      walletConnectProvider.onDisconnect((code, reason) => listener());
    }
  }

  void _pollWallet(_) async {
    try {
      wallet = await getWallet();
      if (wallet != _lastWallet) {
        if (_walletUpdateListener != null) {
          _walletUpdateListener();
        }
      }
      _lastWallet = wallet;
    } catch (err) {
      log("Error polling wallet: $err");
    }
  }

  /// Update polled items including the wallet
  void refresh() {
    _pollWallet(null);
  }

  void onWalletUpdate(void Function() listener) {
    _walletUpdateListener = listener;
  }

  void removeAllListeners() {
    ethereumProvider?.removeAllListeners();
    walletConnectProvider?.removeAllListeners();
    _walletUpdateListener = null;
  }

  void disconnect() async {
    _pollWalletTimer?.cancel();
    removeAllListeners();

    // TODO: How do we close a plain eth provider?
    // _ethereumProvider.call('close'); // ??
    walletConnectProvider?.disconnect();
  }
}

class OrchidWallet {
  final OrchidWeb3Context context;

  Map<TokenType, Token> balances;

  OrchidWallet(this.context, [Map<TokenType, Token> balance]) {
    this.balances = balance ?? {};
  }

  EthereumAddress get address {
    return context.walletAddress;
  }

  /// The balance of the native token type for the chain.
  Token get balance {
    return balances[context.chain.nativeCurrency];
  }

  Token balanceOf(TokenType type) {
    return balances[type];
  }

  @override
  String toString() {
    return 'Wallet{address: $address, balances: $balances}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrchidWallet &&
          runtimeType == other.runtimeType &&
          mapEquals(balances, other.balances);

  @override
  int get hashCode => balances.hashCode;
}
