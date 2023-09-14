import 'package:orchid/orchid/orchid.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'package:orchid/dapp/orchid_web3/wallet_connect_eth_provider.dart';
import 'package:orchid/util/gestures.dart';
import '../orchid/menu/orchid_chain_selector_menu.dart';
import '../dapp/orchid/dapp_settings_button.dart';
import '../dapp/orchid/dapp_wallet_info_button.dart';
import '../dapp/orchid/dapp_wallet_select_button.dart';
import 'package:flutter_svg/svg.dart';

import 'dapp_home_base.dart';

// Note: Currently shared across the Account dapp and Staking dapp.
class DappHomeHeader extends StatefulWidget {
  final OrchidWeb3Context? _web3Context;
  final Set<int>? _contractVersionsAvailable;
  final VoidCallback? _deployContract;
  final int? _contractVersionSelected;
  final void Function(int? version)? _selectContractVersion;
  final Future<void> Function() _disconnect;
  final VoidCallback connectEthereum;
  final void Function(OrchidWeb3Context? web3Context) setNewContext;
  final bool showChainSelector;

  const DappHomeHeader({
    super.key,
    required OrchidWeb3Context? web3Context,
    required this.setNewContext,
    Set<int>? contractVersionsAvailable,
    int? contractVersionSelected,
    void Function(int? version)? selectContractVersion,
    VoidCallback? deployContract,
    required this.connectEthereum,
    required Future<void> Function() disconnect,
    this.showChainSelector = true,
  })  : this._web3Context = web3Context,
        this._contractVersionsAvailable = contractVersionsAvailable,
        this._deployContract = deployContract,
        this._contractVersionSelected = contractVersionSelected,
        this._selectContractVersion = selectContractVersion,
        this._disconnect = disconnect;

  @override
  State<DappHomeHeader> createState() => _DappHomeHeaderState();
}

class _DappHomeHeaderState extends State<DappHomeHeader> {
  var _walletConnectionInProgress = false;
  Chain? _userDefaultChainSelection;

  bool get connected {
    return widget._web3Context != null;
  }

  @override
  Widget build(BuildContext context) {
    return _buildHeader();
  }

  Widget _buildHeader() {
    final deploy = (widget._contractVersionsAvailable?.contains(1) ?? false)
        ? null
        : widget._deployContract;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // logo
        _buildLogo(),
        Row(
          children: [
            if (widget.showChainSelector) _buildChainSelector().left(16),
            _buildHeaderConnectWalletButton().left(16),
            DappSettingsButton(
              contractVersionsAvailable: widget._contractVersionsAvailable,
              contractVersionSelected: widget._contractVersionSelected,
              selectContractVersion: widget._selectContractVersion,
              deployContract: connected ? deploy : null,
            ).left(16),
          ],
        ),
      ],
    );
  }

  Widget _buildLogo() {
    final size = AppSize(context);
    final narrow = (connected && size.narrowerThanWidth(765)) ||
        size.narrowerThanWidth(680);

    return TripleTapGestureDetector(
      onTripleTap: _openLogsPage,
      child: AnimatedContainer(
        duration: millis(300),
        width: narrow ? 40 : 94,
        child: narrow
            ? SvgPicture.asset(OrchidAssetSvg.orchid_logo_small_path,
                height: 38)
            : OrchidAsset.svg.orchid_logo_text,
      ),
    );
  }

  Widget _buildChainSelector() {
    final size = AppSize(context);
    final narrow = (connected && size.narrowerThanWidth(700)) ||
        size.narrowerThanWidth(600);
    final chain = widget._web3Context?.chain ?? _userDefaultChainSelection;
    return SizedBox(
      width: narrow ? 40 : 190,
      height: 40,
      child: OrchidChainSelectorMenu(
        iconOnly: narrow,
        selected: chain,
        onSelection: _switchOrAddChain,
        enabled: true,
      ),
    );
  }

  /// The "connect" button in the header that toggles the connection panel
  Widget _buildHeaderConnectWalletButton() {
    final narrow = AppSize(context).narrowerThanWidth(550);
    final reallyNarrow = AppSize(context).narrowerThanWidth(385);

    final textStyleBase =
        OrchidText.medium_16_025.semibold.black.copyWith(height: 1.8);
    final selectedTextStyle =
        textStyleBase.copyWith(color: Colors.white.withOpacity(0.8));
    final backgroundColor = OrchidColors.tappable;

    return AnimatedCrossFade(
      duration: Duration(milliseconds: 300),
      crossFadeState:
          connected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      // Wallet info button
      firstChild: SizedBox(
        // Hight must be set on each child
        height: 40,
        child: DappWalletInfoButton(
          web3Context: widget._web3Context,
          onDisconnect: widget._disconnect,
          showBalance: !narrow,
          minimalAddress: reallyNarrow,
          // onPressed: _toggleShowConnectPanel,
          disconnect: widget._disconnect,
        ),
      ),
      // Connect button
      secondChild: SizedBox(
        height: 40,
        child: DappWalletSelectButton(
          connected: connected,
          disconnect: widget._disconnect,
          enabled: !_walletConnectionInProgress,
          width: reallyNarrow ? 115 : 164,
          unselectedTextStyle: textStyleBase,
          selectedTextStyle: selectedTextStyle,
          backgroundColor: backgroundColor,
          connectMetamask: widget.connectEthereum,
          connectWalletConnect: () =>
              _uiGuardConnectingState(_connectWalletConnect),
        ),
      ),
    );
  }

  void _switchOrAddChain(Chain chain) async {
    // If there is no current context the user is selecting a default chain for future connection.
    if (widget._web3Context == null) {
      setState(() {
        _userDefaultChainSelection = chain;
      });
      return;
    }
    log("XXX: switch chain: $chain");

    // Handle a WalletConnect switch:
    if (widget._web3Context!.walletConnectProvider != null) {
      await _switchOrAddChainWalletConnect(chain);
      return;
    }

    try {
      if (widget._web3Context?.ethereumProvider != null) {
        await widget._web3Context!.ethereumProvider!
            .walletSwitchChain(chain.chainId);
      }
    } on EthereumUserRejected {
      log("XXX: user rejected switch");
    } on EthereumUnrecognizedChainException {
      log("XXX: chain not recognized, suggesting add");
      _addChain(chain);
    } on EthereumException catch (err) {
      // If metamask gives us an exception that includes text suggesting calling
      // the add chain method we'll assume this was was an unrecognized chain.
      if (err.message.contains('wallet_addEthereumChain')) {
        log("XXX: inferring chain not recognized from exception message, suggesting add. err=$err");
        _addChain(chain);
      }
      if (err.message.contains('already pending for origin')) {
        log("XXX: inferring request pending from exception message: err=$err");
        DappHomeUtil.showRequestPendingMessage(context);
      } else {
        log("Unknown EthereumException in switch chain: $err");
      }
    } catch (err) {
      log("Unknown err in switch chain: $err");
    }
  }

  // WalletConnect does have the notion of multiple chains per wallet connection,
  Future<void> _switchOrAddChainWalletConnect(Chain chain) async {
    log("switchOrAddChainWalletConnect");
    // Dispatch this to avoid a flutter bug?
    Future.delayed(millis(0), () {
      AppDialogs.showConfirmationDialog(
          context: context,
          title: "Switch Chain",
          bodyText:
              "Switching to the ${chain.name} with WalletConnect will require a new connection.\n"
              "Do you wish to drop this session and reconnect?",
          commitAction: () async {
            await widget._disconnect();
            setState(() {
              _userDefaultChainSelection = chain;
            });
            await _uiGuardConnectingState(_connectWalletConnect);
          });
    });
  }

  void _addChain(Chain chain) async {
    if (widget._web3Context == null) {
      throw Exception("Cannot add chain without a web3 context");
    }
    final ethereum = widget._web3Context!.ethereumProvider;
    if (ethereum == null) {
      throw Exception("Cannot add chain without an ethereum provider");
    }
    try {
      await ethereum.walletAddChain(
        chainId: chain.chainId,
        chainName: chain.name,
        nativeCurrency: CurrencyParams(
          name: chain.nativeCurrency.symbol,
          symbol: chain.nativeCurrency.symbol,
          decimals: chain.nativeCurrency.decimals,
        ),
        blockExplorerUrls:
            chain.explorerUrl != null ? [chain.explorerUrl!] : null,
        rpcUrls: [chain.providerUrl],
      );
    } on EthereumUserRejected {
      log("XXX: user rejected add chain");
    } catch (err) {
      log("XXX: add chain failed: $err");
    }
  }

  void _openLogsPage() {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return LoggingPage();
    }));
  }

  Future<void> _uiGuardConnectingState(Future<void> Function() connect) async {
    setState(() {
      _walletConnectionInProgress = true;
    });
    try {
      await connect();
    } finally {
      setState(() {
        _walletConnectionInProgress = false;
      });
    }
  }

  Future<void> _connectWalletConnect() async {
    log("XXX: connectWalletConnect");
    // const walletConnectProjectId = 'bd5be579e9cae68defff05a6fa7b0049'; // test
    const walletConnectProjectId = 'afe2e392884aefdae72d4babb5482ced';

    final chain = _userDefaultChainSelection ?? Chains.Ethereum;
    var wc = await WalletConnectEthereumProvider.init(
      projectId: walletConnectProjectId,
      rpcMap: {
        chain.chainId: chain.providerUrl,
      },
      chains: [chain.chainId],
      // This does not seem to work, otherwise we could simply connect to all
      // of our chains as optional and allow more straightforward switching.
      // optionalChains: [Chains.Gnosis.chainId, 31411234],
      showQrModal: true,
    );
    // consoleLog(wc.impl);
    try {
      log('Before wc connect');
      await wc.connect();
      log('After wc connect');
    } catch (err) {
      log('wc connect/init, err = $err');
      return;
    }
    if (!wc.connected) {
      AppDialogs.showAppDialog(
          context: context,
          title: s.error,
          bodyText: s.failedToConnectToWalletconnect);
      return;
    }

    var web3 = await OrchidWeb3Context.fromWalletConnect(wc);
    widget.setNewContext(web3);
  }
}
