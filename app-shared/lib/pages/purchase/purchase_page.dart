import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/purchase/orchid_pac.dart';
import 'package:orchid/api/purchase/orchid_pac_server.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import 'package:orchid/api/pricing.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/circuit/add_hop_page.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/gradients.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import '../app_text.dart';

class PurchasePage extends StatefulWidget {
  final AddFlowCompletion onAddFlowComplete;

  const PurchasePage({Key key, @required this.onAddFlowComplete})
      : super(key: key);

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  List<StreamSubscription> _rxSubscriptions = List();
  Pricing _pricing;

  // Purchase status overlay state
  bool _showOverlayPane = false;
  String _overlayStatusMessage;
  bool _requiresUserAction = false;
  bool _showHelp = false;

  @override
  void initState() {
    ScreenOrientation.portrait();
    super.initState();
    _rxSubscriptions
        .add(PacTransaction.shared.stream().listen(_pacTransactionUpdated));
    initStateAsync();
  }

  void initStateAsync() async {
    _pricing = await OrchidAPI().pricing().getPricing();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: s.purchase,
      child: buildPage(context),
      lightTheme: true,
    );
  }

  // TODO: Localize
  Widget buildPage(BuildContext context) {
    const String bullet = "•";
    return Stack(
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(left: 30, right: 30, top: 16, bottom: 16),
          child: Column(
            children: <Widget>[
              pady(8),
              _buildInstructions(),
              pady(16),
              _buildPurchaseCardView(
                  pac: OrchidPurchaseAPI.pacTier1,
                  title: s.lowUsage,
                  subtitle: "$bullet " +
                      s.internetBrowsing +
                      "\n$bullet " +
                      s.lowVideoStraming,
                  gradBegin: 0,
                  gradEnd: 2),
              pady(24),
              _buildPurchaseCardView(
                  pac: OrchidPurchaseAPI.pacTier2,
                  title: s.averageUsage,
                  subtitle: "$bullet " +
                      s.internetBrowsing +
                      "\n$bullet " +
                      s.moderateVideoStreaming,
                  gradBegin: -2,
                  gradEnd: 1),
              pady(24),
              _buildPurchaseCardView(
                pac: OrchidPurchaseAPI.pacTier3,
                title: s.highUsage,
                subtitle: "$bullet " +
                    s.videoStreamingCalls +
                    "\n$bullet " +
                    s.gaming,
                gradBegin: -1,
                gradEnd: -1,
              ),
            ],
          ),
        ),
        if (_showOverlayPane) _buildOverlay()
      ],
    );
  }

  Widget _buildOverlay() {
    Size size = MediaQuery.of(context).size;
    return Center(
        child: Container(
            color: _requiresUserAction
                ? Colors.transparent
                : Colors.white24.withOpacity(0.5),
            width: size.width,
            height: size.height,
            child: Center(
                child: IntrinsicHeight(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(16.0))),
                padding:
                    EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 40),
                child: _requiresUserAction
                    ? _buildRequiresUserAction()
                    : _buildProgressOverlay(),
              ),
            ))));
  }

  Column _buildProgressOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircularProgressIndicator(),
        pady(12),
        Text(
          _overlayStatusMessage ?? "",
          style: TextStyle(fontSize: 20),
        )
      ],
    );
  }

  Column _buildRequiresUserAction() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          s.pacPurchaseWaiting, // TODO: Localize
          style: TextStyle(fontSize: 20),
        ),
        pady(16),
        FlatButton(
            color: Colors.blue.shade800,
            child: Text(
              s.retry,
              style: TextStyle(color: Colors.white),
            ), // TODO: Localize
            onPressed: _retryPurchase),
        _showHelp ? _buildHelpExpanded() : _buildHelp()
      ],
    );
  }

  Column _buildHelp() {
    return Column(
      children: <Widget>[
        pady(24),
        LinkText(s.getHelpResolvingIssue,
            style: AppText.linkStyle, onTapped: _expandHelp),
      ],
    );
  }

  Column _buildHelpExpanded() {
    return Column(
      children: <Widget>[
        pady(24),
        FlatButton(
            color: AppText.linkStyle.color,
            child: Text(s.copyDebugInfo, style: TextStyle(color: Colors.white)),
            // TODO: Localize
            onPressed: _copyDebugInfo),
        pady(24),
        LinkText(s.contactOrchid,
            style: AppText.linkStyle, url: "https://orchid.com/help"),
        pady(24),
        FlatButton(
            color: Colors.redAccent,
            child: Text(s.remove, style: TextStyle(color: Colors.white)),
            // TODO: Localize
            onPressed: _deleteTransaction),
      ],
    );
  }

  void _expandHelp() {
    setState(() {
      _showHelp = true;
    });
  }

  void _copyDebugInfo() async {
    PacTransaction tx = await PacTransaction.shared.get();
    Clipboard.setData(
        ClipboardData(text: tx != null ? tx.userDebugString() : '<no tx>'));
  }

  void _retryPurchase() {
    OrchidPACServer().processPendingPACTransaction();
  }

  void _confirmDeleteTransaction() async {
    //var tx = await PacTransaction.shared.get();
    //OrchidPurchaseAPI().finishTransaction(tx.transactionId);
    await PacTransaction.shared.clear();
  }

  void _deleteTransaction() {
    Dialogs.showConfirmationDialog(
        context: context,
        title: s.deleteTransaction,
        body: s.clearThisInProgressTransactionExplain,
        commitAction: _confirmDeleteTransaction);
  }

  Widget _buildInstructions() {
    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
      fontFamily: 'SFProText-Semibold',
    );
    const subtitleStyle = TextStyle(
      color: Colors.grey,
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      fontFamily: 'SFProText-Semibold',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(s.chooseYourPurchase, style: titleStyle),
        pady(16),
        Text(s.basedOnYourBandwidth, style: subtitleStyle),
      ],
    );
  }

  Widget _buildPurchaseCardView(
      {PAC pac,
      String title,
      String subtitle,
      double gradBegin = 0.0,
      double gradEnd = 1.0}) {
    const titleStyle = TextStyle(
        color: Colors.white,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontFamily: 'SFProText-Semibold',
        height: 22.0 / 17.0);
    const subtitleStyle = TextStyle(
      color: Colors.white,
      fontSize: 13.0,
      fontWeight: FontWeight.w300,
      letterSpacing: 0.5,
      fontFamily: 'SFProText-Semibold',
    );
    const valueStyle = TextStyle(
        color: Colors.white,
        fontSize: 18.0,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.38,
        fontFamily: 'SFProText-Regular',
        height: 25.0 / 20.0);
    const valueSubtitleStyle = TextStyle(
        color: Colors.white,
        fontSize: 13.0,
        fontWeight: FontWeight.normal,
        fontFamily: 'SFProText-Regular',
        height: 16.0 / 12.0);

    var usdString = pac.displayName;
    var oxtString =
        _pricing?.toOXT(pac.usdPurchasePrice)?.toStringAsFixed(2) ?? "";

    Gradient grad = VerticalLinearGradient(
        begin: Alignment(0.0, gradBegin),
        end: Alignment(0.0, gradEnd),
        colors: [Color(0xff4e71c2), Color(0xff258993)]);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _purchase(purchase: pac);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: grad,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Row(
            children: <Widget>[
              // left side usage description
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      textAlign: TextAlign.left,
                      style: titleStyle,
                    ),
                    pady(8),
                    FittedBox(
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.left,
                        style: subtitleStyle,
                      ),
                    )
                  ],
                ),
              ),
              padx(4),
              // right side value display
              Expanded(
                flex: 1,
                child: FittedBox(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: <Widget>[
                            Text("$usdString",
                                style: valueStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        pady(2),
                        Visibility(
                          visible: _pricing != null,
                          child: Text("~ $oxtString OXT",
                              style: valueSubtitleStyle),
                        ),
                      ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchase({PAC purchase}) async {
    print("iap: calling purchase: $purchase");

    // Initiate the in-app purchase
    try {
      await OrchidPurchaseAPI().purchase(purchase);
    } catch (err) {
      if (err is SKError) {
        var skerror = err;
        if (skerror.code == OrchidPurchaseAPI.SKErrorPaymentCancelled) {
          print("iap: user cancelled");
          return null;
        }
      }
      print("iap: Error in purchase call: $err");
      _purchaseError();
      return null;
    }
  }

  // Respond to updates of the PAC transaction status
  void _pacTransactionUpdated(PacTransaction tx) async {
    if (tx == null) {
      _clearOverlay();
      return;
    }
    switch (tx.state) {
      case PacTransactionState.Pending:
        _showOverlay(s.preparingPurchase);
        break;
      case PacTransactionState.InProgress:
        _showOverlay(s.fetchingPurchasedPAC);
        break;
      case PacTransactionState.WaitingForRetry:
        _showOverlay(s.retryingPurchasedPac);
        break;
      case PacTransactionState.WaitingForUserAction:
        _showOverlay(s.retryPurchasedPAC, requiresUserAction: true);
        break;
      case PacTransactionState.Error:
        _clearOverlay();
        _purchaseError();
        break;
      case PacTransactionState.Complete:
        await _completeTransaction(tx);
        _clearOverlay();
        break;
    }
  }

  // Collect a completed PAC transaction and apply it to the hop.
  Future<void> _completeTransaction(PacTransaction tx) async {
    print("iap: complete transaction");

    var serverResponse = tx.serverResponse;
    if (serverResponse == null) {
      throw Exception("empty server response");
    }

    String pacAccountString;
    try {
      var pacResponseJson = json.decode(serverResponse);
      pacAccountString = pacResponseJson['config'];
      if (pacAccountString == null) {
        print("iap: error no server response");
        throw Exception("no config in server response");
      }
    } catch (err) {
      print("iap: error decoding server response json: $err");
      throw Exception("invalid server response");
    }

    // Successfully parsed the server response.
    //OrchidPurchaseAPI().finishTransaction(tx.transactionId);
    PacTransaction.shared.clear();

    // Parse the account response and create a hop
    setState(() {
      _overlayStatusMessage = s.setUpAccount;
    });
    ParseOrchidAccountResult parseAccountResult;
    try {
      var existingKeys = await UserPreferences().getKeys();
      parseAccountResult =
          OrchidVPNConfig.parseOrchidAccount(pacAccountString, existingKeys);
    } catch (err) {
      print("iap: error parsing purchased orchid account: $err");
      throw Exception("error in server response");
    }
    if (parseAccountResult != null) {
      var hop = await OrchidVPNConfig.importAccountAsHop(parseAccountResult);
      widget.onAddFlowComplete(hop);
    } else {
      throw Exception("Error setting up account");
    }
  }

  void _showOverlay(String message, {bool requiresUserAction = false}) {
    print("iap: display message: $message");
    setState(() {
      _showOverlayPane = true;
      _overlayStatusMessage = message;
      _requiresUserAction = requiresUserAction;
    });
  }

  void _clearOverlay() {
    setState(() {
      _showOverlayPane = false;
      _overlayStatusMessage = null;
      _requiresUserAction = false;
    });
  }

  /// Handle a purchase error by clearing any error pac transaction and
  /// showing a dialog.
  void _purchaseError() async {
    print("iap: purchase page: showing error");

    // Clear any error tx
    var tx = await PacTransaction.shared.get();
    if (tx.state == PacTransactionState.Error) {
      print("iap: clearing error tx");
      await PacTransaction.shared.clear();
    } else {
      print("iap: purchase error called with incorrect pac tx state");
    }

    await Dialogs.showAppDialog(
      context: context,
      // TODO: Localize
      title: s.purchaseError,
      bodyText: s.thereWasAnErrorInPurchasingContact,
    );
  }

  @override
  void dispose() {
    _rxSubscriptions.forEach((sub) {
      sub.cancel();
    });
    super.dispose();
    ScreenOrientation.reset();
  }

  S get s {
    return S.of(context);
  }
}
