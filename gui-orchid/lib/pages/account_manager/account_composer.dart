import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_text.dart';

class AccountComposerPage extends StatelessWidget {
  final TokenType tokenType;

  AccountComposerPage(this.tokenType);

  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
        child: TitledPage(
            title: 'Account Composer',
            cancellable: true,
            child: AccountComposer(tokenType: tokenType)));
  }
}

class AccountComposer extends StatefulWidget {
  final TokenType tokenType;

  const AccountComposer({Key key, @required this.tokenType}) : super(key: key);

  @override
  _AccountComposerState createState() => _AccountComposerState();
}

class _AccountComposerState extends State<AccountComposer> {
  var _sliderValue = 50.0;
  var _depositField = TextEditingController();
  var _balanceField = TextEditingController();
  var _gasPriceField = TextEditingController();
  var _funds;
  Token _marketGasPrice;

  TokenType get tokenType { return widget.tokenType; }

  @override
  void initState() {
    _funds = tokenType.fromDouble(0.01); // TODO:
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _marketGasPrice = await OrchidEthereumV1().getGasPrice(tokenType.chain);
    _gasPriceField.text = _marketGasPrice.toFixedLocalized(digits: 2);
    setState(() {});
  }

  double _efficiency() {
    return _sliderValue;
  }

  // nullable
  Token _fundsRequiredToCreateAccount() {
    if (_marketGasPrice == null) {
      return null;
    }
    return _marketGasPrice
        .multiplyInt(OrchidContractV1.createAccountMaxGas);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pady(8),
          labelRow(
              labelText: "Total funds to allocate:",
              valueText: _funds.formatCurrency()),
          pady(24),
          fieldRow(
              labelText: "Deposit:",
              trailingText: tokenType.symbol,
              controller: _depositField),
          pady(12),
          fieldRow(
              labelText: "Balance:",
              trailingText: tokenType.symbol,
              controller: _balanceField),
          pady(24),
          labelRow(
            labelText: "Efficiency:",
            valueText: "${_efficiency().toString()}%",
          ),
          buildSlider(),
          pady(16),
          fieldRow(
              labelText: "Gas Price:",
              trailingText: tokenType.symbol,
              controller: _gasPriceField),
          pady(24),
          _buildGasText()
        ],
      ),
    );
  }

  Widget _buildGasText() {
    if (_marketGasPrice == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        "${_fundsRequiredToCreateAccount().toFixedLocalized(digits: 4)}"
        " ${tokenType.symbol} will be allocated"
        " for network fees for the transaction.",
        style: AppText.dialogBody.copyWith(fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget fieldRow(
      {String labelText,
      TextEditingController controller,
      String trailingText}) {
    return Row(
      children: [
        Container(
          width: 80,
          child: label(labelText),
        ),
        padx(8),
        Container(
          width: 130,
          child: AppTextField(
            //height: 40,
            numeric: true,
            controller: controller,
            // trailing: trailingText != null ? Padding(
            //   padding: const EdgeInsets.only(right: 16.0),
            //   child: Text(trailingText),
            // ) : null,
          ),
        ),
        // Text(trailingText),
        Row(
          children: [
            Text(trailingText),
            padx(8),
            Icon(
              Icons.settings,
              color: Colors.grey.withOpacity(0.8),
              size: 22,
            )
          ],
        ),
      ],
    );
  }

  Widget labelRow({String labelText, String valueText, Widget value}) {
    return Row(
      children: [label(labelText), padx(8), value ?? Text(valueText)],
    );
  }

  Widget label(String text) {
    var labelStyle = TextStyle(fontWeight: FontWeight.bold);
    return Text(text, style: labelStyle);
  }

  Widget buildSlider() {
    return Slider(
      activeColor: Colors.deepPurple,
      inactiveColor: Colors.grey,
      value: _sliderValue,
      min: 0,
      max: 100,
      divisions: 100,
      label: _sliderValue.round().toString(),
      onChanged: (double value) {
        setState(() {
          print("value = $value");
          _sliderValue = value;
        });
      },
    );
  }
}
