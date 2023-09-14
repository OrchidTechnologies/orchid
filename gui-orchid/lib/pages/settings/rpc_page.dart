import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_chain_config.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_switch.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/pages/settings/user_configured_chain_panel.dart';

class RpcPage extends StatefulWidget {
  @override
  _RpcPageState createState() => _RpcPageState();
}

class _RpcPageState extends State<RpcPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
        title: s.chainSettings,
        constrainWidth: false,
        child: buildPage(context),
        actions: OrchidUserConfig.isTester ? [_buildAddButton()] : []);
  }

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: UserPreferencesUI().userConfiguredChains.builder((_) {
        return _buildChains().padx(20).top(8).bottom(24);
      }),
    );
  }

  Future<void> _addUserConfiguredChain() async {
    return AppDialogs.showAppDialog(
      context: context,
      title: s.addChain,
      body: UserConfiguredChainPanel(),
      showActions: false,
    );
  }

  Widget _buildAddButton() {
    return IconButton(
      icon: Icon(Icons.add_circle_outline),
      onPressed: _addUserConfiguredChain,
    ).right(8);
  }

  Widget _buildChains() {
    final knownChains = Chains.knownChains.values.toList();
    // bump Ethereum to the top of the list
    knownChains.remove(Chains.Ethereum);
    knownChains.insert(0, Chains.Ethereum);

    final userConfiguredChains = UserPreferencesUI().userConfiguredChains.get()!;
    final chains =
        userConfiguredChains.cast<Chain>() + knownChains.cast<Chain>();
    // chain config will not be null
    final config = ChainConfig.map(UserPreferencesUI().chainConfig.get()!);

    return ListView.builder(
        itemCount: chains.length,
        itemBuilder: (context, index) {
          final chain = chains[index];
          return _ChainItem(
            chain: chain,
            config: config[chain.chainId],
            showEnableSwitch: chain != Chains.Ethereum,
          ).bottom(16);
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

  S get s {
    return context.s;
  }
}

class _ChainItem extends StatefulWidget {
  final Chain chain;
  final ChainConfig? config;
  final bool showEnableSwitch;

  const _ChainItem({
    Key? key,
    required this.chain,
    required this.config,
    this.showEnableSwitch = true,
  }) : super(key: key);

  @override
  State<_ChainItem> createState() => _ChainItemState();
}

class _ChainItemState extends State<_ChainItem> {
  var _rpcController = TextEditingController();
  var _priceController = NumericValueFieldController();
  late bool _show;
  List<Widget> _testResults = [];

  @override
  void initState() {
    super.initState();
    _rpcController.text = widget.config?.rpcUrl ?? '';
    _show = widget.config?.enabled ?? true;
  }

  bool get isUserConfigured => widget.chain is UserConfiguredChain;

  @override
  Widget build(BuildContext context) {
    return _buildPanel();
  }

  OrchidPanel _buildPanel() {
    final labelWidth = isUserConfigured ? 130.0 : 65.0;
    final backgroundFillColor = isUserConfigured
        ? OrchidColors.purpleCaption
        : OrchidPanel.defaultBackgroundFill;
    final backgroundGradient = isUserConfigured
        ? LinearGradient(colors: [
            Colors.black,
            Colors.black,
          ])
        : OrchidPanel.defaultBackgroundGradient;
    final showEnabledSwitch = widget.showEnableSwitch && !isUserConfigured;
    final showDelete = isUserConfigured;

    return OrchidPanel(
      backgroundFillColor: backgroundFillColor,
      backgroundGradient: backgroundGradient,
      child: Column(
        children: [
          // header
          pady(8),
          Row(
            children: [
              SizedBox(height: 24, width: 24, child: widget.chain.icon),
              Text(widget.chain.name).title.height(1.8).left(12),
              Spacer(),
              if (showEnabledSwitch)
                Row(
                  children: [
                    Text(s.show + ':').button,
                    _buildSwitch(_show),
                  ],
                ),
              if (showDelete) _buildDelete(widget.chain as UserConfiguredChain),
            ],
          ),

          AnimatedVisibility(
            show: _show,
            child: Column(
              children: [
                // body
                _buildRPCRow(labelWidth).top(12).right(12),
                if (isUserConfigured)
                  _buildPriceRow(labelWidth).top(8).right(12),

                // last test results
                if (_testResults.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _testResults
                        .map((e) => SizedBox(
                              height: 24,
                              child: Row(
                                children: [
                                  e,
                                ],
                              ),
                            ))
                        .toList()
                        .cast<Widget>()
                        .surroundedWith(Divider(color: Colors.white)),
                  ).top(16),

                // test button
                if (_show)
                  OrchidActionButton(
                    width: 110,
                    text: s.test.toUpperCase(),
                    onPressed: _testRpc,
                    enabled: _rpcController.text == '' ||
                        _rpcController.text.isEmpty ||
                        _rpcIsValid(),
                  ).top(20).bottom(8),
              ],
            ),
          ),
        ],
      ).padx(20).top(8).bottom(16),
    );
  }

  Row _buildRPCRow(double labelWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: labelWidth, child: Text(s.rpc + ':').title),
        Expanded(
          child: OrchidTextField(
            enabled: !isUserConfigured,
            controller: _rpcController,
            onChanged: (_) {
              _update();
            },
            onClear: _update,
            hintText: widget.chain.defaultProviderUrl ==
                    Chains.Ethereum.defaultProviderUrl
                ? widget.chain.defaultProviderUrl.substring(0, 34)
                : widget.chain.defaultProviderUrl,
          ),
        ),
      ],
    );
  }

  Row _buildPriceRow(double labelWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: labelWidth, child: Text(s.tokenPrice + ':').title),
        Expanded(
          child: OrchidTextField(
            // TODO:
            numeric: true,
            enabled: false,
            controller: _priceController.textController,
            // onChanged: (_) { _update(); },
            // onClear: _update,
            hintText: (widget.chain.nativeCurrency.exchangeRateSource
                    as FixedPriceToken)
                .usdPrice
                .formatCurrency(locale: context.locale, precision: 2)
          ),
        ),
      ],
    );
  }

  void _showLogs() {
    Navigator.pushNamed(context, '/settings/log');
  }

  void _testRpc() async {
    setState(() {
      _testResults = [
        OrchidCircularProgressIndicator.smallIndeterminate(),
      ];
    });

    try {
      await OrchidEthereumV1().getGasPrice(widget.chain, refresh: true);
      _testResults.last = Text(s.fetchGasPrice + ': ' + s.ok).body2;
    } catch (err) {
      log('test rpc: gas price failed for chain: $widget.chain, err=$err');
      _testResults.last = Text(s.fetchGasPrice + ': ' + s.failed)
          .body2
          .tappable
          .linkButton(onTapped: _showLogs);
    }
    _testResults.add(OrchidCircularProgressIndicator.smallIndeterminate());
    setState(() {});
    try {
      await OrchidEthereumV1().getLotteryPot(
          chain: widget.chain,
          funder: EthereumAddress.zero,
          signer: EthereumAddress.zero);
      _testResults.last = Text(s.fetchLotteryPot + ': ' + s.ok).body2;
    } catch (err) {
      log('test rpc: get lottery pot failed for chain: $widget.chain, err=$err');
      _testResults.last = Text(s.fetchLotteryPot + ': ' + s.failed)
          .body2
          .tappable
          .linkButton(onTapped: _showLogs);
    }
    setState(() {});
  }

  bool _rpcIsValid() {
    return _rpcController.text.looksLikeUrl;
  }

  void _update() async {
    setState(() {
      _testResults = [];
    });
    var text = _rpcIsValid() ? _rpcController.text : null;
    int chainId = widget.chain.chainId;
    var newConfig = ChainConfig(
      chainId: chainId,
      enabled: _show,
      rpcUrl: text,
    );
    // chain config will not be null
    var list = UserPreferencesUI()
        .chainConfig
        .get()!
        .where((e) => e.chainId != chainId)
        .toList();

    if (!newConfig.isEmpty) {
      list.add(newConfig);
    }
    await UserPreferencesUI().chainConfig.set(list);
    setState(() {});
  }

  Future<void> _confirmDelete(UserConfiguredChain userConfiguredChain) async {
    await AppDialogs.showConfirmationDialog(
        context: context,
        title: s.deleteChainQuestion,
        bodyText: s.deleteUserConfiguredChain + ': ' + userConfiguredChain.name,
        commitAction: () async {
          await UserPreferencesUI()
              .userConfiguredChains
              .remove(userConfiguredChain);
        });
  }

  Widget _buildDelete(UserConfiguredChain userConfiguredChain) {
    return IconButton(
      icon: Icon(
        Icons.delete_forever,
        color: Colors.white,
      ),
      onPressed: () {
        _confirmDelete(userConfiguredChain);
      },
    );
  }

  Widget _buildSwitch(bool value) {
    return OrchidSwitch(
      value: value,
      onChanged: (bool value) {
        _show = !_show;
        _update();
      },
    );
  }
}
