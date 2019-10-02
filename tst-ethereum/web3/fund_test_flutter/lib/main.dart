import 'dart:math';

import 'package:flutter/material.dart';
import 'accommodate_keyboard.dart';
import 'orchid_api.dart';
import 'log_view.dart';
import 'style.dart';

void main() => runApp(FundOrchidApp());

class FundOrchidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var title = 'Orchid: Lottery Funding';
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: FundingPage(title: title),
    );
  }
}

class FundingPage extends StatefulWidget {
  FundingPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _FundingPageState createState() => _FundingPageState();
}

class _FundingPageState extends State<FundingPage> {
  final LogViewController _logViewController = LogViewController();

  TextEditingController _fundAmountTextController = TextEditingController();
  Account _fundFromAccount;
  double _amountToFund; // OXT

  TextEditingController _potAddressTextController = TextEditingController();
  FocusNode _potAddressFocusNode = FocusNode();
  String _potAddressToFund;
  double _potCurrentBalance; // OXT

  @override
  void initState() {
    super.initState();

    var params = OrchidAPI.getURLParams();
    setState(() {
      _potAddressToFund = params.potAddress;
      _potAddressTextController.text = _potAddressToFund;
      _amountToFund = params.amount;
      _fundAmountTextController.text = "$_amountToFund";
    });

    _updateBalances();

    //_potAddressFocusNode.requestFocus();
    //_potAddressFocusNode.addListener(() {
    //setState(() {});
    //});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: RaisedButton(
          elevation: 0,
          child: Text("Debug"),
          onPressed: () {
            OrchidAPI.debug();
          },
        ),
        body: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    const double horizontalPad = 16;
    double availableScreenWidth =
        MediaQuery.of(context).size.width - 2 * horizontalPad;

    String ethBalance = weiToEth(_fundFromAccount?.ethBalance);
    String oxtBalance = weiToOxt(_fundFromAccount?.oxtBalance);

    // Note: the keyboard accommodation is working in the flutter mobile but not web.
    return AccommodateKeyboard(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: min(availableScreenWidth, 550)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Spacer(flex: 1),

              // Logo
              _buildLogo(),

              // Account balance
              _buildField(
                  topMargin: 24,
                  label: 'Account: ',
                  initialValue: _fundFromAccount?.address?.toUpperCase() ??
                      "<No Accounts Found>"),
              _buildField(
                  label: 'ETH Balance: ', initialValue: ethBalance + " Ξ"),

              _buildField(
                  label: 'OXT Balance: ', initialValue: oxtBalance + " X"),

              // Pot address entry
              ..._buildPotAddressEntry(),

              // Current pot balance
              Opacity(
                  opacity: _potAddressToFund != null ? 1.0 : 0.4,
                  child: _buildField(
                      label: 'Current Balance: ',
                      initialValue: _potAddressToFund != null
                          ? _potCurrentBalance.toString() + "X"
                          : "")),

              // Pot funding amount entry and transfer button
              AbsorbPointer(
                absorbing: _potAddressToFund == null,
                child: Opacity(
                    opacity: _potAddressToFund != null ? 1.0 : 0.4,
                    child: _buildAmountEntry()),
              ),
              SizedBox(height: 36),

              // Log view
              LogView(controller: _logViewController),
              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  // Build the labeld display fields
  Widget _buildField(
      {double topMargin = 12, String label, String initialValue}) {
    var labelTheme = Theme.of(context).textTheme.headline;
    var valueTheme =
        Theme.of(context).textTheme.title.copyWith(color: Colors.deepPurple);
    return Padding(
      padding: EdgeInsets.only(top: topMargin),
      child: Row(children: [
        Text(label, textAlign: TextAlign.left, style: labelTheme),
        Expanded(
          child: Text(initialValue,
              textAlign: TextAlign.left,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: valueTheme),
        ),
      ]),
    );
  }

  List<Widget> _buildPotAddressEntry() {
    var labelTheme = Theme.of(context).textTheme.headline;
    return [
      SizedBox(height: 24),
      Text('Lottery Pot Address to Fund:',
          textAlign: TextAlign.left, style: labelTheme),
      SizedBox(height: 12),
      Container(
        decoration: _potAddressToFund != null
            ? textFieldFocusedDecoration
            : textFieldEnabledDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _potAddressTextController,
            autocorrect: false,
            textAlign: TextAlign.left,
            maxLines: 1,
            focusNode: _potAddressFocusNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Paste address...",
            ),
            onChanged: (text) {
              setState(() {
                _potAddressToFund = OrchidAPI.isAddress(text) ? text : null;
                _updateBalances();
              });
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildLogo() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: neutral_5, width: 2))),
      child: Row(
        children: <Widget>[
          Image.asset("name_logo.png", height: 50),
          SizedBox(
            width: 10,
          ),
          Image.asset("wallet.png", height: 46),
        ],
      ),
    );
  }

  Widget _buildAmountEntry() {
    var labelTheme = Theme.of(context).textTheme.headline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 24),
        Text('Amount to Transfer:',
            textAlign: TextAlign.left, style: labelTheme),
        SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: _amountToFund != null
                    ? textFieldFocusedDecoration
                    : textFieldEnabledDecoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _fundAmountTextController,
                    keyboardType: TextInputType.number,
                    autocorrect: false,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Amount in OXT",
                    ),
                    onChanged: (text) {
                      setState(() {
                        _amountToFund =
                            double.tryParse(text); // null if not int
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Container(
              child: RaisedButton(
                  disabledColor: Colors.grey,
                  color: teal_4,
                  elevation: 0,
                  child: Text(
                    "Transfer",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _amountToFund != null ? _onTransactPressed : null),
            )
          ],
        ),
      ],
    );
  }

  void _onTransactPressed() {
    _logViewController.log("Transaction submitted");
    String amount = BigInt.from(_amountToFund * 1e18).toString();
    OrchidAPI.fundPot(_potAddressToFund, amount).then((result) {
      _logViewController.log("fund transaction: $result");
      _logViewController.log("Transaction transfer: $_amountToFund OXT");
      _logViewController.log(result);
      setState(() {
        _amountToFund = null;
        _fundAmountTextController.clear();
      });
      _updateBalances();
    });
  }

  void _updateBalances() {
    if (_potAddressToFund != null) {
      OrchidAPI.getPotBalance(_potAddressToFund).then((String balance) {
        setState(() {
          this._potCurrentBalance =
              BigInt.parse(balance).toDouble() / 1e18; // wei->unit
        });
        debugPrint("pot current balance=${_potCurrentBalance}");
      });
    }

    OrchidAPI.getAccount().then((Account account) {
      setState(() {
        this._fundFromAccount = account;
      });
      debugPrint(
          "account: address=${account.address}, oxt=${account.oxtBalance}");
    });
  }

  // Convert a string value representing wei to an ETH value with the specified
  // number of decimal places of precision retained.
  String weiToEth(/*@Nullable*/ String wei, {int digits = 4}) {
    if (wei == null) {
      return "0";
    }
    double val = (BigInt.parse(wei) / BigInt.from(1e18));
    // Round to 'digits'
    int fac = pow(10, digits);
    return ((val * fac).round() / fac).toString();
  }

  // Convert OXT-wei to an OXT value with the specified
  // number of decimal places of precision retained.
  String weiToOxt(/*@Nullable*/ String wei, {int digits = 4}) {
    return weiToEth(wei, digits: digits);
  }
}
