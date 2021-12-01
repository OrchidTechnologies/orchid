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
  static int contextId = 0; // for logging
  final int id;

  /// The web3 provider, either wrapping an Ethereum provider or a Wallet Connect provider.
  final Web3Provider web3;

  final Chain chain;
  final EthereumAddress walletAddress;

  /// If the web3 provider wraps ethereum this is the underlying provider.
  final Ethereum ethereumProvider;

  /// If the web3 provider wraps wallet connect this is the underlying provider.
  final WalletConnectProvider walletConnectProvider;

  // Indicates that this context has been disconnected and should no longer be alive.
  // This is a workaround to ensure that listeners do not fire in this state.
  bool disposed = false;

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
    this.ethereumProvider,
    this.walletConnectProvider,
  }) : this.id = (contextId += 1) {
    log("context created: $id");
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
    void invokeListener(List<String> accounts) {
      // log("XXX: context ($id) callback onAccountsChanged");
      // Ensure that we don't fire callbacks after this context has been destroyed.
      if (!disposed) {
        listener(accounts);
      }
    }
    if (ethereumProvider != null) {
      ethereumProvider.onAccountsChanged(invokeListener);
    } else {
      walletConnectProvider.onAccountsChanged(invokeListener);
    }
  }

  void onChainChanged(void Function(int chainId) listener) {
    void invokeListener(int chainId) {
      // log("XXX: context ($id) callback onChainChanged");
      // Ensure that we don't fire callbacks after this context has been destroyed.
      if (!disposed) {
        listener(chainId);
      }
    }
    if (ethereumProvider != null) {
      ethereumProvider.onChainChanged(invokeListener);
    } else {
      walletConnectProvider.onChainChanged(invokeListener);
    }
  }

  /*
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
   */

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
      log("Error polling wallet: $err, context id = $id");
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
    //log("XXX: context ($id) removing listeners");
    ethereumProvider?.removeAllListeners();
    walletConnectProvider?.removeAllListeners();
    _walletUpdateListener = null;
    //log("XXX: after removing listeners: ${ethereumProvider.listenerCount()}");
  }

  void disconnect() async {
    log("XXX: disconnect context ($id)");

    removeAllListeners();
    _pollWalletTimer?.cancel();

    // TODO: How do we close a plain eth provider?
    // _ethereumProvider.call('close'); // ??
    walletConnectProvider?.disconnect();

    disposed = true;
  }

  @override
  String toString() {
    return 'OrchidWeb3Context{id: $id, chain: ${chain.chainId}, walletAddress: $walletAddress}';
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
