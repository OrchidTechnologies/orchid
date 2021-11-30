import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/orchid_web3/v1/orchid_web3_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:styled_text/styled_text.dart';

import 'dapp_button.dart';
import 'orchid_form_fields.dart';

class AddFundsPane extends StatefulWidget {
  final OrchidWeb3Context context;

  // TODO: This will be available through context
  final OrchidWallet wallet;

  final EthereumAddress signer;
  final VoidCallback onTransaction;

  const AddFundsPane({
    Key key,
    @required this.context,
    @required this.wallet,
    @required this.signer,
    @required this.onTransaction,
  }) : super(key: key);

  @override
  _AddFundsPaneState createState() => _AddFundsPaneState();
}

class _AddFundsPaneState extends State<AddFundsPane> {
  final _addBalanceField = TokenValueFieldController();
  final _addDepositField = TokenValueFieldController();
  bool _txPending = false;

  OrchidWallet get wallet {
    return widget.wallet;
  }

  @override
  void initState() {
    super.initState();
    _addBalanceField.addListener(_formFieldChanged);
    _addDepositField.addListener(_formFieldChanged);
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    if (wallet?.balance == null) {
      return Container();
    }
    var tokenType = wallet.balance.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTokenValueField(
          type: tokenType,
          controller: _addBalanceField,
          label: "Balance" + ':',
        ),
        pady(4),
        LabeledTokenValueField(
          type: tokenType,
          controller: _addDepositField,
          label: "Deposit" + ':',
        ),
        pady(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DappButton(
                text: "ADD FUNDS",
                onPressed: _addFundsFormEnabled ? _addFunds : null),
          ],
        ),
        pady(32),
        _buildInstructions(),
      ],
    );
  }

  Widget _buildInstructions() {
    return StyledText(
      style: OrchidText.caption,
      textAlign: TextAlign.center,
      text: "Add funds to your Orchid Account balance and/or deposit."
          "  For guidance on sizing your account see <link>orchid.com</link>",
      tags: {
        'link':
            OrchidText.caption.linkStyle.link(OrchidUrls.partsOfOrchidAccount),
      },
    );
  }

  void _formFieldChanged() {
    // Update UI
    setState(() {});
  }

  bool get _addBalanceFieldValid {
    var value = _addBalanceField.value;
    return value != null && value < wallet.balance;
  }

  bool get _addDepositFieldValid {
    var value = _addDepositField.value;
    return value != null && value < wallet.balance;
  }

  bool get _addFundsFormEnabled {
    if (_txPending) {
      return false;
    }
    if (_addBalanceFieldValid && _addDepositFieldValid) {
      var total = _addBalanceField.value + _addDepositField.value;
      return total > wallet.balance.type.zero && total <= wallet.balance;
    }
    return false;
  }

  void _addFunds() async {
    if (!_addBalanceFieldValid) {
      return;
    }
    setState(() {
      _txPending = true;
    });
    try {
      var txHash = await OrchidWeb3V1(widget.context).orchidAddFunds(
        wallet: wallet,
        signer: widget.signer,
        addBalance: _addBalanceField.value,
        addEscrow: _addDepositField.value,
      );
      UserPreferences().addTransaction(txHash);
      _addBalanceField.clear();
      _addDepositField.clear();
      setState(() {});
      widget.onTransaction();
    } catch (err) {
      log("Error on add funds: $err");
    }
    setState(() {
      _txPending = false;
    });
  }
}
