import 'package:orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/api/preferences/dapp_transaction.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/token_price_builder.dart';
import 'package:orchid/util/units.dart';
import 'package:styled_text/styled_text.dart';
import 'dapp_button.dart';
import 'dapp_error_row.dart';
import 'dapp_tab_context.dart';
import 'orchid_form_fields.dart';

class AddFundsPane extends StatefulWidget {
  final OrchidWeb3Context context;
  final EthereumAddress signer;
  final bool enabled;

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
    @required this.addFunds,
    this.enabled,
  }) : super(key: key);

  @override
  _AddFundsPaneState createState() => _AddFundsPaneState();
}

class _AddFundsPaneState extends State<AddFundsPane> with DappTabWalletContext {
  OrchidWeb3Context get web3Context => widget.context;

  TypedTokenValueFieldController _addBalanceField;
  TypedTokenValueFieldController _addDepositField;

  @override
  void initState() {
    super.initState();
    // Note: The field controller captures the token type so this form must be
    // Note: rebuilt on chain changes.
    _addBalanceField = TypedTokenValueFieldController(type: tokenType);
    _addBalanceField.addListener(_formFieldChanged);
    _addDepositField = TypedTokenValueFieldController(type: tokenType);
    _addDepositField.addListener(_formFieldChanged);
  }

  @override
  Widget build(BuildContext context) {
    var allowance = wallet?.allowanceOf(tokenType) ?? tokenType.zero;
    return TokenPriceBuilder(
        tokenType: tokenType,
        seconds: 30,
        builder: (USD tokenPrice) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allowance != null && allowance.gtZero())
                Text(s.currentTokenPreauthorizationAmount(tokenType.symbol,
                        allowance.formatCurrency(locale: context.locale)))
                    .body2
                    .top(8),
              LabeledTokenValueField(
                enabled: widget.enabled,
                type: tokenType,
                controller: _addBalanceField,
                label: s.balance,
                usdPrice: tokenPrice,
                error: _addBalanceFieldError || _netAddError,
              ).top(16),
              LabeledTokenValueField(
                enabled: widget.enabled,
                type: tokenType,
                controller: _addDepositField,
                label: s.deposit,
                usdPrice: tokenPrice,
                error: _addDepositFieldError || _netAddError,
              ).top(16),
              if (_netAddError)
                DappErrorRow(text: 'Total exceeds wallet balance.').top(16),
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
        });
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
    return value != null && value <= (walletBalance ?? tokenType.zero);
  }

  bool get _addBalanceFieldError {
    return walletBalance != null && !_addBalanceFieldValid;
  }

  bool get _addDepositFieldValid {
    var value = _addDepositField.value;
    return value != null && value <= (walletBalance ?? tokenType.zero);
  }

  bool get _addDepositFieldError {
    return walletBalance != null && !_addDepositFieldValid;
  }

  bool get _addFundsFormEnabled {
    return !txPending && _netAddValid;
  }

  bool get _netAddValid {
    if (walletBalance == null) {
      return false;
    }
    final zero = tokenType.zero;
    if (_addBalanceFieldValid && _addDepositFieldValid) {
      var total = _totalAdd;
      return total > zero && total <= walletBalance;
    }
    return false;
  }

  Token get _totalAdd {
    return _addBalanceField.value + _addDepositField.value;
  }

  bool get _netAddError {
    return (_addBalanceFieldValid && _addDepositFieldValid) &&
        !_netAddValid &&
        _totalAdd.gtZero();
  }

  void _addFunds() async {
    if (!_addBalanceFieldValid) {
      return;
    }
    setState(() {
      txPending = true;
    });
    try {
      final txHashes = await widget.addFunds(
        wallet: wallet,
        signer: widget.signer,
        addBalance: _addBalanceField.value,
        addEscrow: _addDepositField.value,
      );

      // Persisting the transaction(s) will update the UI elsewhere.
      UserPreferences().addTransactions(txHashes.map((hash) => DappTransaction(
          transactionHash: hash, chainId: widget.context.chain.chainId)));

      _addBalanceField.clear();
      _addDepositField.clear();
      setState(() {});
    } catch (err, stack) {
      log('Error on add funds: $err, $stack');
    }
    setState(() {
      txPending = false;
    });
  }

  @override
  void dispose() {
    _addBalanceField.removeListener(_formFieldChanged);
    _addDepositField.removeListener(_formFieldChanged);
    super.dispose();
  }
}
