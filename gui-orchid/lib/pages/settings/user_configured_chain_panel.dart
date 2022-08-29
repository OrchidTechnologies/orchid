// @dart=2.12
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/eth_rpc.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';

class UserConfiguredChainPanel extends StatefulWidget {
  const UserConfiguredChainPanel({Key? key}) : super(key: key);

  @override
  State<UserConfiguredChainPanel> createState() =>
      _UserConfiguredChainPanelState();
}

class _UserConfiguredChainPanelState extends State<UserConfiguredChainPanel> {
  var _name = TextEditingController();

  var _providerUrl = TextEditingController();
  bool _rpcTestPassed = false;
  Widget? _testResult;
  int? _chainId;

  var _tokenPrice = NumericValueFieldController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // String name,
        OrchidLabeledTextField(
          label: "Chain name" + ':',
          hintText: "Name...",
          controller: _name,
          // TODO:
          onChanged: (_) => _updateForm(),
          onClear: _updateForm,
        ),

        // String defaultProviderUrl,
        OrchidLabeledTextField(
          label: "RPC Url" + ':',
          hintText: "https://...",
          controller: _providerUrl,
          onChanged: (_) => _updateForm(),
          onClear: _updateForm,
        ).top(8),

        // double token USD price
        OrchidLabeledNumericField(
          label: "Token Price USD" + ':',
          controller: _tokenPrice,
          onChange: (_) => setState(() {}),
          // onClear: () => setState(() {}),
        ).top(8),

        if (_testResult != null) _testResult.top(24).left(8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTestButton(),
            _buildSaveButton().left(16),
          ],
        ).top(32)
      ],
    );
  }

  void _updateForm() {
    log("XXX: update");
    _rpcTestPassed = false;
    _testResult = null;
    setState(() {});
  }

  OrchidActionButton _buildTestButton() {
    return OrchidActionButton(
      width: 110,
      text: s.test.toUpperCase(),
      onPressed: _testRpc,
      enabled: _formValid(), // && !_rpcTestPassed,
    );
  }

  OrchidActionButton _buildSaveButton() {
    return OrchidActionButton(
      width: 110,
      text: s.save.toUpperCase(),
      onPressed: _saveChain,
      enabled: _rpcTestPassed,
    );
  }

  bool _formValid() {
    return _providerUrl.text.looksLikeUrl &&
        _name.text.isNotEmpty &&
        _tokenPrice.text.isNotEmpty;
  }

  String get _url {
    return _providerUrl.text.trim().toLowerCase();
  }

  void _testRpc() async {
    setState(() {
      _testResult = OrchidCircularProgressIndicator.smallIndeterminate();
    });
    _chainId = null;
    _rpcTestPassed = false;
    var text;
    try {
      final result = await EthereumJsonRpc.ethJsonRpcCall(
          url: _url, method: 'eth_chainId');
      log("XXX: test rpc: result = $result");
      _chainId = int.parse(Hex.remove0x(result), radix: 16);
      _rpcTestPassed = true;
      text = "Chain reachable.  Chain id: $_chainId.";
    } catch (err) {
      log("XXX: test rpc: err = $err");
      text = "Test failed: ``$err``";
    }
    _testResult = Row(
      children: [
        Flexible(child: Text(text, maxLines: 5).caption),
      ],
    );
    setState(() {});
  }

  void _saveChain() async {
    if (_chainId == null) {
      throw Exception();
    }
    final chain = UserConfiguredChain(
      name: _name.text,
      chainId: _chainId,
      defaultProviderUrl: _providerUrl.text,
      tokenPriceUSD: USD(double.parse(_tokenPrice.text)),
    );
    await UserPreferences().userConfiguredChains.add(chain);
    Navigator.pop(context);
  }
}
