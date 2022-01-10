import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/orchid_web3/orchid_erc20.dart';
import 'package:orchid/api/orchid_web3/v0/orchid_web3_v0.dart';

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

  /// Lottery contract versions available on this chain
  Set<int> contractVersionsAvailable;

  OrchidWeb3Context._({
    this.web3,
    this.chain,
    this.walletAddress,
    this.ethereumProvider,
    this.walletConnectProvider,
  }) : this.id = (contextId += 1) {
    log("context created: $id");
  }

  Future<void> _init() async {
    contractVersionsAvailable = Set.unmodifiable(await _findContractVersions());
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

    await context._init();

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

    await context._init();

    return context;
  }

  /// Fetch the native token balance for
  Future<Token> getBalance() async {
    return chain.nativeCurrency
        .fromInt(await web3.getBalance(walletAddress.toString()));
  }

  Future<OrchidWallet> getWallet() async {
    Map<TokenType, Token> balances = {};
    Map<TokenType, Token> allowances = {};

    balances[chain.nativeCurrency] = await getBalance();

    // TODO: If we support other erc20 (non-native) token choices in future we will
    // TODO: need to generalize this to specify the set that the wallet should
    // TODO: display for a given chain.
    // Also find the OXT balance if on main net or test
    if (chain.isEthereum || OrchidUserParams().test) {
      try {
        var oxt = OrchidERC20(context: this, tokenType: TokenTypes.OXT);
        balances[TokenTypes.OXT] = await oxt.getERC20Balance(walletAddress);
        allowances[TokenTypes.OXT] = await oxt.getERC20Allowance(
            owner: walletAddress,
            spender: OrchidContractV0.lotteryContractAddressV0);
      } catch (err) {
        log("Error: Unable to find erc20 balance: $err");
      }
    }

    return OrchidWallet(
        context: this, balances: balances, allowances: allowances);
  }

  Future<Set<int>> _findContractVersions() async {
    Set<int> set = {};

    var code =
        await web3.getCode(OrchidContractV0.lotteryContractAddressV0String);
    if (code != "0x") {
      set.add(0);
    }

    code = await web3.getCode(OrchidContractV1.lotteryContractAddressV1);
    if (code != "0x") {
      set.add(1);
    }

    return set;
  }

  /// Wallet addresses changed
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

  /// Provider chain changed
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

  // Allowances for any erc20 tokens tracked.
  Map<TokenType, Token> allowances;

  OrchidWallet({
    this.context,
    Map<TokenType, Token> balances,
    Map<TokenType, Token> allowances,
  })  : this.balances = balances ?? {},
        this.allowances = allowances ?? {};

  EthereumAddress get address {
    return context.walletAddress;
  }

  /// The balance of the native token type for the chain.
  Token get balance {
    return balances[context.chain.nativeCurrency];
  }

  /// Fetch the native token balance for
  Future<Token> getBalance() async {
    return context.getBalance();
  }

  Token get oxtBalance {
    return balances[TokenTypes.OXT];
  }

  Token balanceOf(TokenType type) {
    return balances[type];
  }

  Token allowanceOf(TokenType type) {
    return allowances[type];
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
