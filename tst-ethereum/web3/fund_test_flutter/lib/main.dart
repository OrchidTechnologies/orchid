import 'package:flutter_site/style.dart';
import 'package:flutter_web/material.dart';
import 'js_api.dart';

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
  FocusNode _focusNode = FocusNode();
  TextEditingController _amountTextController = TextEditingController();
  Account _account;
  String _accountKeyToFund;
  int _amountToFund;
  String _logText = "";

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    OrchidJS.getAccount().then((Account account) {
      setState(() {
        this._account = account;
      });
      debugPrint(
          "account: address=${account.address}, oxt=${account.oxtBalance}");
    });
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: RaisedButton(
          elevation: 0,
          child: Text("Debug"),
          onPressed: () {
            OrchidJS.debug();
          },
        ),
        body: buildContent(context));
  }

  Widget buildContent(BuildContext context) {
    var labelTheme = Theme.of(context).textTheme.headline;
    var valueTheme =
        Theme.of(context).textTheme.title.copyWith(color: Colors.deepPurple);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 530),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Spacer(flex: 1),
            buildLogo(),
            SizedBox(height: 24),
            Text('Account: ', textAlign: TextAlign.left, style: labelTheme),
            Text(_account?.address?.toUpperCase() ?? "<No Accounts Found>",
                textAlign: TextAlign.left, style: valueTheme),
            SizedBox(height: 12),
            Text('ETH Balance: ', textAlign: TextAlign.left, style: labelTheme),
            Text((_account?.ethBalance ?? "") + " Ξ",
                textAlign: TextAlign.left, style: valueTheme),
            SizedBox(height: 12),
            Text('OXT Balance: ', textAlign: TextAlign.left, style: labelTheme),
            Text((_account?.oxtBalance ?? "") + " X",
                textAlign: TextAlign.left, style: valueTheme),

            // Address Entry
            SizedBox(height: 24),
            Text('Lottery Pot Address to Fund:',
                textAlign: TextAlign.left, style: labelTheme),
            SizedBox(height: 12),
            Container(
              decoration: _accountKeyToFund != null
                  ? textFieldFocusedDecoration
                  : textFieldEnabledDecoration,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autocorrect: false,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Paste address...",
                  ),
                  onChanged: (text) {
                    setState(() {
                      _accountKeyToFund =
                          OrchidJS.isAddress(text) ? text : null;
                    });
                  },
                ),
              ),
            ),

            // Amount entry and transfer button
            AbsorbPointer(
              absorbing: _accountKeyToFund == null,
              child: Opacity(
                  opacity: _accountKeyToFund != null ? 1.0 : 0.4,
                  child: buildAmountEntry(labelTheme)),
            ),
            SizedBox(height: 36),

            // Log view
            Visibility(
              visible: _logText.length > 0,
              child: buildLog(),
            ),
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget buildLog() {
    return Container(
      constraints: BoxConstraints(maxHeight: 400),
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Text(
          _logText,
          textAlign: TextAlign.left,
          style: logStyle,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 2.0, color: neutral_5),
      ),
    );
  }

  Widget buildLogo() {
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

  Widget buildAmountEntry(TextStyle labelTheme) {
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
                    controller: _amountTextController,
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
                        _amountToFund = int.tryParse(text); // null if not int
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
                  onPressed: _amountToFund != null ? onTransactPressed : null),
            )
          ],
        ),
      ],
    );
  }

  void onTransactPressed() {
    OrchidJS.fundPot(_accountKeyToFund, _amountToFund).then((result) {
      setState(() {
        _logText += "Transaction transfer: $_amountToFund OXT\n";
        _logText += result;
        _amountToFund = null;
        _amountTextController.clear();
      });
      OrchidJS.getAccount().then((Account account) {
        setState(() {
          this._account = account;
        });
      });
    });
  }
}
