import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_text.dart';

class ImportKeyPage extends StatefulWidget {
  @override
  _ImportKeyPageState createState() => _ImportKeyPageState();
}

class _ImportKeyPageState extends State<ImportKeyPage> {
  var _secretController = TextEditingController();
  BigInt _secret;

  @override
  void initState() {
    super.initState();
    _secretController.addListener(_onSecretChange);
  }

  void _onSecretChange() {
    try {
      var text = _secretController.text;
      if (text.toLowerCase().startsWith('0x')) {
        text = text.substring(2);
      }
      var bigInt = BigInt.parse(text, radix: 16);
      //  TODO: check this validation
      if (bigInt > BigInt.from(0) && bigInt < ((BigInt.from(1)<<256)-BigInt.from(1)) ) {
        _secret = bigInt;
      } else {
        _secret = null;
      }
    } catch (err) {
      _secret = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: "Import Key",
      cancellable: true,
      actions: <Widget>[_buildSaveButton()],
      child: Container(
        decoration: BoxDecoration(gradient: AppGradients.basicGradient),
        child: Column(
          children: <Widget>[
            pady(16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Private Key:",
                      style: AppText.textLabelStyle.copyWith(fontSize: 18))),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 0, bottom: 24),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextFormField(
                  autocorrect: false,
                  autofocus: false,
                  style: AppText.logStyle.copyWith(color: AppColors.grey_2),
                  controller: _secretController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
                // TODO: This is used elsewhere, factor out
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  border: Border.all(width: 2.0, color: AppColors.neutral_5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    bool isValid = _secret != null;
    return FlatButton(
        child: Text(
          "Save",
          style: AppText.actionButtonStyle.copyWith(
              // TODO: We need to get the TitledPage to publish colors on the context (theme)
              color: isValid ? Colors.white : Colors.white.withOpacity(0.4)),
        ),
        onPressed: isValid
            ? () {
                Navigator.pop(context, _secret);
              }
            : null);
  }

  @override
  void dispose() {
    _secretController.removeListener(_onSecretChange);
  }
}
