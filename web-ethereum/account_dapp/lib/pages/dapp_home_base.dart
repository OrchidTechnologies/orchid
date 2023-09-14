import 'package:orchid/dapp/orchid_web3/v1/orchid_contract_deployment_v1.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/dapp/orchid_web3/v1/orchid_eth_v1_web3.dart';

class DappHomeStateBase<T extends StatefulWidget> extends State<T> {
  OrchidWeb3Context? web3Context;

  /// The contract version defaulted or selected by the user.
  /// Null if no contacts are available.
  int? _contractVersionSelectedValue;

  int? get contractVersionSelected {
    return _contractVersionSelectedValue;
  }

  void selectContractVersion(int? version) {
    // if (version == _contractVersionSelected) { return; }
    log('XXX: version = $version');
    _contractVersionSelectedValue = version;
    if (version != null) {
      onContractVersionChanged(version);
    }
  }

  Set<int>? get contractVersionsAvailable {
    return web3Context?.contractVersionsAvailable;
  }

  /// If the user has previously connected accounts reconnect without requiring
  /// the user to hit the connect button.
  Future<void> checkForExistingConnectedAccounts() async {
    try {
      var accounts = await ethereum?.getAccounts() ?? [];
      if (accounts.isNotEmpty) {
        log('connect: User already has accounts, connecting.');
        await Future.delayed(Duration(seconds: 0), () {
          connectEthereum();
        });
      } else {
        log('connect: No connected accounts, require the user to initiate.');
      }
    } catch (err) {
      log('connect: Error checking getAccounts: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @protected
  Future<void> deployContract() async {
    final deploy = OrchidContractDeployment(web3Context!);
    if (await deploy.deployIfNeeded()) {
      _onAccountOrChainChange();
    }
  }

  Future<void> connectEthereum() async {
    log("XXX: connectEthereum");
    try {
      await _tryConnectEthereum();
    } on EthereumException catch (err) {
      // Infer the "request already pending" exception from the exception text.
      if (err.message.contains('already pending for origin')) {
        log("XXX: inferring request pending from exception message: err=$err");
        DappHomeUtil.showRequestPendingMessage(context);
      } else {
        log("Unknown EthereumException in connect: $err");
      }
    } catch (err) {
      log("Unknown err in connect ethereum: $err");
    }
  }

  Future<void> _tryConnectEthereum() async {
    if (!Ethereum.isSupported) {
      AppDialogs.showAppDialog(
          context: context,
          title: s.noWallet,
          bodyText: s.noWalletOrBrowserNotSupported);
      return;
    }

    if (ethereum == null) {
      log("no ethereum provider");
      return;
    }
    var web3 = await OrchidWeb3Context.fromEthereum(ethereum!);
    setNewContext(web3);
  }

  // Init a new context, disconnecting any old context and registering listeners
  void setNewContext(OrchidWeb3Context? newWeb3Context) async {
    log('set new context: $newWeb3Context');

    // Clear the old context, removing listeners and disposing of it properly.
    web3Context?.disconnect();

    // Register listeners on the new context
    newWeb3Context?.onAccountsChanged((accounts) {
      log('web3: accounts changed: $accounts');
      if (accounts.isEmpty) {
        setNewContext(null);
      } else {
        _onAccountOrChainChange();
      }
    });
    newWeb3Context?.onChainChanged((chainId) {
      log('web3: chain changed: $chainId');
      _onAccountOrChainChange();
    });
    // _context?.onConnect(() { log('web3: connected'); });
    // _context?.onDisconnect(() { log('web3: disconnected'); });
    newWeb3Context?.onWalletUpdate(() {
      // Update the UI
      setState(() {});
    });

    // Install the new context here and as the UI provider
    web3Context = newWeb3Context;
    try {
      _setAppWeb3Provider(newWeb3Context);
    } catch (err, stack) {
      log('set new context: error setting app web3 provider: $err,\n$stack');
    }

    // The context was replaced or updated. Check various attributes.
    // check the contract
    // if (_web3Context != null) {
    //   if (_contractVersionsAvailable == null ||
    //       _contractVersionsAvailable.isEmpty) {
    //     await _noContract();
    //   }
    // }

    try {
      web3Context?.refresh();
    } catch (err) {
      log('set new context: error in refreshing context: $err');
    }

    // Default the contract version
    if (contractVersionsAvailable != null) {
      final selectedVersion =
          web3Context!.contractVersionsAvailable!.contains(1)
              ? 1
              : web3Context!.contractVersionsAvailable!.contains(0)
                  ? 0
                  : null;
      selectContractVersion(selectedVersion);
    } else {
      selectContractVersion(null);
    }
    // XXX
    // if (OrchidUserParams().test) {
    //   _contractVersionSelected = 0;
    // }

    // Subclasses should override and update the UI here
  }

  // For contracts that may exist on chains other than main net we ensure that
  // all requests go through the web3 context.
  void _setAppWeb3Provider(OrchidWeb3Context? web3Context) {
    // log("XXX: setAppWeb3Provider: $web3Context");
    if (web3Context != null &&
        contractVersionSelected != null &&
        contractVersionSelected! > 0) {
      OrchidEthereumV1.setWeb3Provider(OrchidEthereumV1Web3Impl(web3Context));
    } else {
      OrchidEthereumV1.setWeb3Provider(null);
    }
  }

  /// Update on change of address or chain by rebuilding the web3 context.
  void _onAccountOrChainChange() async {
    if (web3Context == null) {
      return;
    }

    // Check chain before constructing web3
    // var chainId = await ethereum.getChainId();
    // if (!Chains.isKnown(chainId)) {
    //   return _invalidChain();
    // }

    // Recreate the context wrapper
    var context = null;
    try {
      if (web3Context?.ethereumProvider != null) {
        context = await OrchidWeb3Context.fromEthereum(
            web3Context!.ethereumProvider!);
      } else {
        context = await OrchidWeb3Context.fromWalletConnect(
            web3Context!.walletConnectProvider!);
      }
    } catch (err) {
      log('Error constructing web context:');
    }
    setNewContext(context);
  }

  void onContractVersionChanged(int version) async {
    _setAppWeb3Provider(web3Context);
    setState(() {});
    // Subclasses should override and update the UI here
  }

  Future<void> disconnect() async {
    web3Context?.disconnect();
    setState(() {
      web3Context = null;
      _contractVersionSelectedValue = null;
    });
  }
}

class DappHomeUtil {
  static void showRequestPendingMessage(BuildContext context) {
    AppDialogs.showAppDialog(
      context: context,
      title: context.s.checkWallet,
      bodyText: context.s.checkYourWalletAppOrExtensionFor,
    );
  }
}
