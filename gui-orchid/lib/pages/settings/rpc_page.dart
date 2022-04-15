import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_chain_config.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';

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
        child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            pady(8),
            _buildChains(),
            pady(24),
          ],
        ).padx(20),
      ),
    );
  }

  Widget _buildChains() {
    var chains = Chains.unfiltered.values.toList();

    // bump Ethereum to the top of the list
    chains.remove(Chains.Ethereum);
    chains.insert(0, Chains.Ethereum);

    final config = ChainConfig.map(UserPreferences().chainConfig.get());
    return Column(
        children: chains.map((chain) {
      return _ChainItem(
        chain: chain,
        config: config[chain.chainId],
        showEnableSwitch: chain != Chains.Ethereum,
      ).bottom(16);
    }).toList()
        // .cast<Widget>()
        // .separatedWith(Divider(color: Colors.white)),
        );
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
  final ChainConfig config;
  final bool showEnableSwitch;

  const _ChainItem({
    Key key,
    @required this.chain,
    @required this.config,
    this.showEnableSwitch = true,
  }) : super(key: key);

  @override
  State<_ChainItem> createState() => _ChainItemState();
}

class _ChainItemState extends State<_ChainItem> {
  var _controller = TextEditingController();
  bool _show;
  List<Widget> _testResults = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.config?.rpcUrl;
    _show = widget.config?.enabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final labelWidth = 65.0;
    return OrchidPanel(
      child: Column(
        children: [
          // header
          pady(8),
          Row(
            children: [
              SizedBox(height: 24, child: widget.chain.icon),
              Text(widget.chain.name).title.height(1.8).left(12),
              Spacer(),
              if (widget.showEnableSwitch)
                Row(
                  children: [
                    Text(s.show + ':').button,
                    _buildSwitch(_show),
                  ],
                )
            ],
          ),

          // body
          AnimatedVisibility(
            show: _show,
            child: Column(
              children: [
                // rpc field
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: labelWidth, child: Text(s.rpc + ':').title),
                    Expanded(
                      child: OrchidTextField(
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        controller: _controller,
                        onChanged: (_) {
                          _update();
                        },
                        onClear: _update,
                        hintText: widget.chain.providerUrl ==
                                Chains.defaultEthereumProviderUrl
                            ? widget.chain.providerUrl.substring(0, 34)
                            : widget.chain.providerUrl,
                      ),
                    ),
                  ],
                ).top(12),

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
                    width: 70,
                    text: "TEST",
                    onPressed: _testRpc,
                    enabled: _controller.text == null ||
                        _controller.text.isEmpty ||
                        _rpcIsValid(),
                  ).top(20).bottom(8),
              ],
            ),
          ),
        ],
      ).padx(16).top(8).bottom(16),
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
    return _controller.text.toLowerCase().startsWith('https://');
  }

  void _update() async {
    setState(() {
      _testResults = [];
    });
    var text = _rpcIsValid() ? _controller.text : null;
    int chainId = widget.chain.chainId;
    var newConfig = ChainConfig(
      chainId: chainId,
      enabled: _show,
      rpcUrl: text,
    );
    var list = UserPreferences()
        .chainConfig
        .get()
        .where((e) => e.chainId != chainId)
        .toList();

    if (!newConfig.isEmpty) {
      list.add(newConfig);
    }
    await UserPreferences().chainConfig.set(list);
    setState(() {});
  }

  Widget _buildSwitch(bool value) {
    return Switch(
      activeColor: OrchidColors.active,
      inactiveThumbColor: OrchidColors.inactive,
      inactiveTrackColor: OrchidColors.inactive,
      value: value,
      onChanged: (bool value) {
        _show = !_show;
        _update();
      },
    );
  }
}
