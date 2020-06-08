import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_pricing.dart';
import 'package:orchid/api/purchase/orchid_pac.dart';
import 'package:orchid/api/purchase/orchid_pac_server.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
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
import '../app_colors.dart';
import '../app_sizes.dart';
import '../app_text.dart';
import 'package:intl/intl.dart';

class PurchasePage extends StatefulWidget {
  final AddFlowCompletion onAddFlowComplete;
  final bool cancellable;

  const PurchasePage(
      {Key key, @required this.onAddFlowComplete, this.cancellable = false})
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
    // Disable price display
    //_pricing = await OrchidAPI().pricing().getPricing();
    //setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      decoration: BoxDecoration(color: Colors.transparent),
      title: s.purchase,
      child: buildPage(context),
      lightTheme: true,
      cancellable: widget.cancellable,
    );
  }

  Widget buildPage(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 30, right: 30, top: 0, bottom: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  children: <Widget>[
                    if (AppSize(context).tallerThan(AppSize.iphone_xs_max))
                      pady(64),
                    pady(8),
                    _buildInstructions(),
                    pady(16),
                    _buildPurchaseCardView(
                        pac: OrchidPurchaseAPI.pacTier1,
                        subtitle: _buildTierDescriptionText(100),
                        gradBegin: 0,
                        gradEnd: 2),
                    pady(24),
                    _buildPurchaseCardView(
                        pac: OrchidPurchaseAPI.pacTier2,
                        subtitle: _buildTierDescriptionText(200),
                        gradBegin: -2,
                        gradEnd: 1),
                    pady(24),
                    _buildPurchaseCardView(
                      pac: OrchidPurchaseAPI.pacTier3,
                      subtitle: _buildTierDescriptionText(500),
                      gradBegin: -1,
                      gradEnd: -1,
                    ),
                    pady(32),
                    _buildInfoPanel(
                        svgName: "assets/svg/orchid_icon.svg",
                        title: s.onlyForTheOrchidApp,
                        body: s.orchidTokensInTheFormOfAccessCreditsAreUnable),
                    pady(19),
                    _buildInfoPanel(
                        svgName: "assets/svg/bandwidth_icon.svg",
                        title: s.bandwidthValueWillVary,
                        body:
                            s.bandwidthIsPurchasedInAVpnMarketplaceSoPriceWill,
                        linkText: "Learn more",
                        linkUrl: 'https://www.orchid.com/' // TODO:
                        )
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showOverlayPane) _buildOverlay()
      ],
    );
  }

  TextSpan _buildTierDescriptionText(int gb) {
    const subtitleStyle =
        TextStyle(color: Color(0xffF1FFF8), fontSize: 13.0, height: 1.33);
    var subtitleStyleBold = subtitleStyle.copyWith(fontWeight: FontWeight.bold);
    return TextSpan(
      children: [
        TextSpan(text: s.approximately + "\n", style: subtitleStyle),
        TextSpan(text: gb.toString() + s.gb, style: subtitleStyleBold),
        TextSpan(text: " " + s.ofTraffic, style: subtitleStyle)
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
          s.pacPurchaseWaiting,
          style: TextStyle(fontSize: 20),
        ),
        pady(16),
        FlatButton(
            color: Colors.blue.shade800,
            child: Text(
              s.retry,
              style: TextStyle(color: Colors.white),
            ),
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
            onPressed: _copyDebugInfo),
        pady(24),
        LinkText(s.contactOrchid,
            style: AppText.linkStyle, url: "https://orchid.com/help"),
        pady(24),
        FlatButton(
            color: Colors.redAccent,
            child: Text(s.remove, style: TextStyle(color: Colors.white)),
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
        color: AppColors.neutral_3,
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        height: 1.33);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(s.chooseYourAmount, style: titleStyle),
        pady(16),
        Text(s.payOnlyForWhatYouUseWithVpnCreditsOnly, style: subtitleStyle),
      ],
    );
  }

  Widget _buildPurchaseCardView(
      {PAC pac,
      String title,
      TextSpan subtitle,
      double gradBegin = 0.0,
      double gradEnd = 1.0}) {
    const titleStyle = TextStyle(
        color: Colors.white,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontFamily: 'SFProText-Semibold',
        height: 22.0 / 17.0);
    const valueStyle = TextStyle(
        color: Colors.white,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.38,
        fontFamily: 'SFProText-Regular',
        height: 25.0 / 20.0);
    const valueSubtitleStyle = TextStyle(
        color: Colors.white,
        fontSize: 13.0,
        fontWeight: FontWeight.normal,
        fontFamily: 'SFProText-Regular',
        height: 16.0 / 12.0);

    var usdString = NumberFormat("0.00").format(pac.usdPurchasePrice.value);
    var oxtString = NumberFormat("0.00")
        .format(_pricing?.toOXT(pac.usdPurchasePrice)?.value ?? 0);

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
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // left side usage description
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (title != null)
                      Text(
                        title,
                        textAlign: TextAlign.left,
                        style: titleStyle,
                      ),
                    if (title != null) pady(8),
                    FittedBox(
                      child: RichText(
                        text: subtitle,
                        textAlign: TextAlign.left,
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
                  fit: BoxFit.scaleDown,
                  child: Column(children: [
                    Row(children: <Widget>[
                      RichText(
                          text: TextSpan(
                        children: [
                          TextSpan(
                              text: "$usdString ",
                              style: valueStyle.copyWith(
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: "USD",
                              style: valueStyle.copyWith(
                                  fontWeight: FontWeight.normal)),
                        ],
                      ))
                    ]),
                    pady(2),
                    Visibility(
                      visible: _pricing != null,
                      child:
                          Text("~ $oxtString OXT", style: valueSubtitleStyle),
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

  Widget _buildInfoPanel(
      {String svgName,
      String title,
      String body,
      String linkText,
      String linkUrl}) {
    var style = TextStyle(fontSize: 12, height: 1.25);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SvgPicture.asset(svgName, width: 24, height: 24),
      padx(19),
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: style.copyWith(fontWeight: FontWeight.bold),
          ),
          pady(3),
          Text(body, style: style),
          if (linkText != null) pady(10),
          if (linkText != null)
            LinkText(linkText,
                style: AppText.linkStyle
                    .copyWith(fontSize: 12, fontWeight: FontWeight.normal),
                url: linkUrl),
        ],
      ))
    ]);
  }

  Future<void> _purchase({PAC purchase}) async {
    log("iap: calling purchase: $purchase");

    // Initiate the in-app purchase
    try {
      await OrchidPurchaseAPI().purchase(purchase);
    } catch (err) {
      if (err is SKError) {
        var skerror = err;
        if (skerror.code == OrchidPurchaseAPI.SKErrorPaymentCancelled) {
          log("iap: user cancelled");
          return null;
        }
      }
      log("iap: Error in purchase call: $err");
      _purchaseError(rateLimitExceeded: err is PACPurchaseExceedsRateLimit);
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
        _showOverlay(s.retryingPurchasedPAC);
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
    log("iap: complete transaction");

    var serverResponse = tx.serverResponse;
    if (serverResponse == null) {
      throw Exception("empty server response");
    }

    String pacAccountString;
    try {
      var pacResponseJson = json.decode(serverResponse);
      pacAccountString = pacResponseJson['config'];
      if (pacAccountString == null) {
        log("iap: error no server response");
        throw Exception("no config in server response");
      }
    } catch (err) {
      log("iap: error decoding server response json: $err");
      throw Exception("invalid server response");
    }

    // Successfully parsed the server response.
    //OrchidPurchaseAPI().finishTransaction(tx.transactionId);
    PacTransaction.shared.clear();

    // Record the purchase for rate limiting
    try {
      PAC pac = OrchidPurchaseAPI.pacForProductId(tx.productId);
      OrchidPurchaseAPI.addPurchaseToRateLimit(pac);
    } catch (err) {
      log("pac: Unable to find pac for product id!");
    }

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
      log("iap: error parsing purchased orchid account: $err");
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
    log("iap: display message: $message");
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
  void _purchaseError({bool rateLimitExceeded = false}) async {
    log(
        "iap: purchase page: showing error, rateLimitExceeded: $rateLimitExceeded");

    // Clear any error tx
    var tx = await PacTransaction.shared.get();
    if (tx != null && tx.state == PacTransactionState.Error) {
      log("iap: clearing error tx");
      await PacTransaction.shared.clear();
    } else {
      log("iap: purchase error called with incorrect pac tx state");
    }

    await Dialogs.showAppDialog(
      context: context,
      title: s.purchaseError,
      bodyText: rateLimitExceeded
          ? s.weAreSorryButThisPurchaseWouldExceedTheDaily
          : s.thereWasAnErrorInPurchasingContact,
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
