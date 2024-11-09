import 'package:orchid/dapp/orchid_web3/orchid_erc20.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/orchid/builder/token_price_builder.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:styled_text/styled_text.dart';
import '../dapp/orchid/dapp_button.dart';
import '../dapp/orchid/dapp_error_row.dart';
import '../dapp/orchid/dapp_tab_context.dart';
import '../orchid/field/orchid_labeled_token_value_field.dart';

class AddFundsPane extends StatefulWidget {
  final OrchidWeb3Context? context;
  final EthereumAddress? signer;
  final bool enabled;

  // Token type can override the default currency for use in V0.
  final tokenType;

  // Callback to add the funds
  final Future<void> Function({
    required OrchidWallet? wallet,
    required EthereumAddress? signer,
    required Token addBalance,
    required Token addEscrow,
    required ERC20PayableTransactionCallbacks? callbacks,
  }) addFunds;

  const AddFundsPane({
    Key? key,
    required this.context,
    required this.signer,
    required this.addFunds,
    required this.tokenType,
    this.enabled = false,
  }) : super(key: key);

  @override
  _AddFundsPaneState createState() => _AddFundsPaneState();
}

class _AddFundsPaneState extends State<AddFundsPane> with DappTabWalletContext {
  OrchidWeb3Context? get web3Context => widget.context;

  late TypedTokenValueFieldController _addBalanceField;
  late TypedTokenValueFieldController _addDepositField;

  @override
  TokenType get tokenType => widget.tokenType;

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
    // log("dapp add funds: tokentype = $tokenType");
    var allowance = wallet?.allowanceOf(tokenType) ?? tokenType.zero;
    return TokenPriceBuilder(
        tokenType: tokenType,
        seconds: 30,
        builder: (USD? tokenPrice) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allowance.gtZero())
                Text(s.currentTokenPreauthorizationAmount(tokenType.symbol,
                        allowance.formatCurrency(locale: context.locale)))
                    .body2
                    .top(8),
              OrchidLabeledTokenValueField(
                enabled: widget.enabled,
                type: tokenType,
                controller: _addBalanceField,
                label: s.balance,
                usdPrice: tokenPrice,
                error: _addBalanceFieldError || _netAddError,
              ).top(16),
              OrchidLabeledTokenValueField(
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
                  DappTransactionButton(
                    text: s.addFunds,
                    onPressed: _addFundsFormEnabled ? _addFunds : null,
                    txPending: txPending,
                  ),
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
    return value != null &&
        value <= (walletBalanceOf(tokenType) ?? tokenType.zero);
  }

  bool get _addBalanceFieldError {
    return walletBalanceOf(tokenType) != null && !_addBalanceFieldValid;
  }

  bool get _addDepositFieldValid {
    var value = _addDepositField.value;
    return value != null &&
        value <= (walletBalanceOf(tokenType) ?? tokenType.zero);
  }

  bool get _addDepositFieldError {
    return walletBalanceOf(tokenType) != null && !_addDepositFieldValid;
  }

  bool get _addFundsFormEnabled {
    return !txPending && _netAddValid;
  }

  bool get _netAddValid {
    if (walletBalanceOf(tokenType) == null) {
      return false;
    }
    final zero = tokenType.zero;
    if (_addBalanceFieldValid && _addDepositFieldValid) {
      var total = _totalAdd;
      return total > zero && total <= walletBalanceOf(tokenType)!;
    }
    return false;
  }

  Token get _totalAdd {
    // null guarded by _addBalanceFieldValid and _addDepositFieldValid
    return _addBalanceField.value! + _addDepositField.value!;
  }

  bool get _netAddError {
    return (_addBalanceFieldValid && _addDepositFieldValid) &&
        !_netAddValid &&
        _totalAdd.gtZero();
  }

  // This generic add funds method can be delegated to either the V0 or V1 impls and so must accommodate
  // ERC20 token approvals and transactions.
  void _addFunds() async {
    if (!_addBalanceFieldValid) {
      return;
    }
    setState(() {
      txPending = true;
    });

    final progress = ERC20PayableTransactionCallbacks(
      onApprovalCallback: (txHash, seriesIndex, seriesTotal) async {
        await UserPreferencesDapp().addTransaction(DappTransaction(
          transactionHash: txHash,
          chainId: web3Context!.chain.chainId /*always Ethereum*/,
          type: DappTransactionType.addFunds,
          subtype: "approve",
          series_index: seriesIndex,
          series_total: seriesTotal,
        ));
      },
      onTransactionCallback: (txHash, seriesIndex, seriesTotal) async {
        await UserPreferencesDapp().addTransaction(DappTransaction(
          transactionHash: txHash,
          chainId: web3Context!.chain.chainId,
          // always Ethereum
          type: DappTransactionType.addFunds,
          // TODO: Localize
          subtype: "push",
          series_index: seriesIndex,
          series_total: seriesTotal,
        ));
      },
    );

    try {
      await widget.addFunds(
        wallet: wallet,
        signer: widget.signer,
        // nulls guarded by _addBalanceFieldValid and _addDepositFieldValid
        addBalance: _addBalanceField.value!,
        addEscrow: _addDepositField.value!,
        callbacks: progress,
      );

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
