import 'dart:io';

import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:styled_text/styled_text.dart';

import 'dapp_button.dart';
import 'orchid_form_fields.dart';
import 'package:orchid/util/localization.dart';

class AddFundsPane extends StatefulWidget {
  final OrchidWeb3Context context;
  final EthereumAddress signer;
  final TokenType tokenType;

  // Callback to add the funds
  final Future<List<String>> Function({
    OrchidWallet wallet,
    EthereumAddress signer,
    Token addBalance,
    Token addEscrow,
  }) addFunds;

  const AddFundsPane({
    Key key,
    @required this.context,
    @required this.signer,
    @required this.tokenType,
    @required this.addFunds,
  }) : super(key: key);

  @override
  _AddFundsPaneState createState() => _AddFundsPaneState();
}

class _AddFundsPaneState extends State<AddFundsPane> {
  final _addBalanceField = TokenValueFieldController();
  final _addDepositField = TokenValueFieldController();
  bool _txPending = false;

  OrchidWallet get wallet {
    return widget.context.wallet;
  }

  // The wallet balance of the configured token type
  Token get walletBalance {
    return wallet?.balanceOf(widget.tokenType);
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
    if (walletBalance == null) {
      return Container();
    }
    var allowance = wallet.allowanceOf(widget.tokenType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allowance != null && allowance.gtZero())
          Text(s.currentTokenPreauthorizationAmount(
                  widget.tokenType.symbol, allowance.formatCurrency(locale: context.locale)))
              .body2
              .bottom(16)
              .top(8),
        LabeledTokenValueField(
          type: widget.tokenType,
          controller: _addBalanceField,
          label: s.balance + ':',
        ),
        pady(4),
        LabeledTokenValueField(
          type: widget.tokenType,
          controller: _addDepositField,
          label: s.deposit + ':',
        ),
        pady(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DappButton(
                text: s.addFunds,
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
      text: s.addFundsToYourOrchidAccountBalanceAndorDeposit +
          ' ' +
          s.forGuidanceOnSizingYourAccountSee,
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
    return value != null && value < walletBalance;
  }

  bool get _addDepositFieldValid {
    var value = _addDepositField.value;
    return value != null && value < walletBalance;
  }

  bool get _addFundsFormEnabled {
    if (_txPending) {
      return false;
    }
    if (_addBalanceFieldValid && _addDepositFieldValid) {
      var total = _addBalanceField.value + _addDepositField.value;
      return total > walletBalance.type.zero && total <= walletBalance;
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
      var txHashes = await widget.addFunds(
        wallet: wallet,
        signer: widget.signer,
        addBalance: _addBalanceField.value,
        addEscrow: _addDepositField.value,
      );

      // Persisting the transaction(s) will update the UI elsewhere.
      UserPreferences().addTransactions(txHashes);

      _addBalanceField.clear();
      _addDepositField.clear();
      setState(() {});
    } catch (err, stack) {
      log('Error on add funds: $err, $stack');
    }
    setState(() {
      _txPending = false;
    });
  }

  @override
  void dispose() {
    _addBalanceField.removeListener(_formFieldChanged);
    _addDepositField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
