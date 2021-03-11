import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/purchase/orchid_pac.dart';
import 'package:orchid/api/purchase/orchid_pac_server.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/gradients.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/loading.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:orchid/util/units.dart';
import '../app_colors.dart';
import '../app_sizes.dart';
import '../app_text.dart';

typedef PurchasePageCompletion = void Function(); // TODO: return

class PurchasePage extends StatefulWidget {
  final EthereumAddress signer;
  final PurchasePageCompletion completion;
  final bool cancellable; // show the close button instead of a back arrow

  const PurchasePage(
      {Key key,
      @required this.signer,
      @required this.completion,
      this.cancellable = false})
      : super(key: key);

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  List<StreamSubscription> _subscriptions = [];

  PACStoreStatus _storeStatus;

  List<PAC> _pacs;

  @override
  void initState() {
    ScreenOrientation.portrait();
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    initProducts();

    _storeStatus = await OrchidPACServer().storeStatus();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      decoration: BoxDecoration(color: Colors.transparent),
      title: s.buyCredits,
      child: buildPage(context),
      lightTheme: true,
      cancellable: widget.cancellable,
    );
  }

  Widget buildPage(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 30, right: 30, top: 0, bottom: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: <Widget>[
                      if (AppSize(context).tallerThan(AppSize.iphone_12_max))
                        pady(64),
                      pady(12),
                      _buildInstructions(),
                      pady(16),
                      _buildPacList(),
                      pady(32),
                      _buildPreferredProviderText()
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_storeOpen) _buildStoreDown()
        ],
      ),
    );
  }

  Widget _buildStoreDown() {
    Size size = MediaQuery.of(context).size;
    return Center(
        child: Container(
            color: Colors.white24.withOpacity(0.5),
            width: size.width,
            height: size.height,
            child: Center(
                child: IntrinsicHeight(
              child: Padding(
                padding:
                    EdgeInsets.only(left: 64, right: 64, top: 40, bottom: 40),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(16.0))),
                  padding:
                      EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "The Orchid Store is temporarily unavailable.  "
                        "Please check back in a few minutes.",
                        style: TextStyle(color: Colors.black, fontSize: 13.0),
                      ),
                      pady(8),
                      LinkText(
                        "See orchid.com for help.",
                        overflow: TextOverflow.visible,
                        style: AppText.linkStyle.copyWith(fontSize: 13.0),
                        url: 'https://orchid.com/help',
                      ),
                    ],
                  ),
                ),
              ),
            ))));
  }

  var checkRowStyle = const TextStyle(
      color: Color(0xFF3A3149),
      fontSize: 15.0,
      height: 20.0 / 15.0,
      letterSpacing: -0.24);

  Widget _buildInstructions() {
    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
      fontFamily: 'SFProText-Semibold',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(s.onetimePurchase, style: titleStyle),
        pady(16),
        _buildCheckRow(s.spentOnlyWhenTheVpnIsActive),
        pady(8),
        _buildCheckRow(s.noSubscriptionCreditsDontExpire),
        pady(8),
        _buildCheckRow(s.unlimitedDevicesAndSharing),
        pady(12),
      ],
    );
  }

  Widget _buildPreferredProviderText() {
    const text = "Purchased credit accounts connect exclusively to our";
    const linkText = "preferred providers";
    const linkUrl = "https://www.orchid.com/preferredproviders";
    return RichText(
        text:
            TextSpan(style: TextStyle(fontStyle: FontStyle.italic), children: [
      TextSpan(
          text: text + " ",
          style: TextStyle(color: Colors.black, fontSize: 15)),
      LinkTextSpan(
        text: linkText,
        url: linkUrl,
        style: AppText.linkStyle
            .copyWith(fontSize: 15.0, fontStyle: FontStyle.italic),
      )
    ]));
  }

  Row _buildCheckRow(String text) {
    return _buildCheckRowRich(TextSpan(text: text, style: checkRowStyle));
  }

  Row _buildCheckRowRich(TextSpan text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("✓"),
        padx(16),
        Flexible(child: RichText(text: text, maxLines: 2)),
      ],
    );
  }

  Widget _buildPacList() {
    if (_pacs == null) {
      return LoadingIndicator(height: 50);
    }
    if (_pacs.isEmpty) {
      return LoadingIndicator(
          height: 50, text: "No PACs available at this time.");
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _fixedPacList()
        /*
         _pacs.map(
            (pac) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildPacPurchaseCard(pac),
            ),
          )
          .toList(),
           */
        );
  }

  // TODO: This assumes three pre-defined pac tiers rather than the list.
  List<Widget> _fixedPacList() {
    if (_pacs.isEmpty || _pacs.length < 3) {
      log("iap: pacs not ready: $_pacs");
      return [];
    }
    // TODO: Hard-coded expected ids
    var pacTier1 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier1';
    var pacTier2 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier2';
    var pacTier3 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier3';
    var pac1 = _pacs.firstWhere((pac) => pac.productId == pacTier1);
    var pac2 = _pacs.firstWhere((pac) => pac.productId == pacTier2);
    var pac3 = _pacs.firstWhere((pac) => pac.productId == pacTier3);

    return [
      _buildPurchaseCardView(
          pac: pac1,
          title: s.tryOutOrchid,
          subtitle: _buildPurchaseDescriptionText(
            text: "- " + s.goodForBrowsingAndLightActivity,
          ),
          gradBegin: 0,
          gradEnd: 2),
      pady(24),
      _buildPurchaseCardView(
          pac: pac2,
          title: s.average,
          subtitle: _buildPurchaseDescriptionText(
            text: "- " +
                s.goodForAnIndividual +
                "\n" +
                "- " +
                s.shortToMediumTermUsage,
          ),
          gradBegin: -2,
          gradEnd: 1),
      pady(24),
      _buildPurchaseCardView(
        pac: pac3,
        title: s.heavy,
        subtitle: _buildPurchaseDescriptionText(
          text: "- " +
              s.goodForBandwidthheavyUsesSharing +
              "\n" +
              "- " +
              s.longerTermUsage,
        ),
        gradBegin: -1,
        gradEnd: -1,
      ),
    ];
  }

  // TODO: Legacy?
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
        height: 20.0 / 17.0);
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

    /*
    var usdString = formatCurrency(pac.localPurchasePrice, ifNull: '...');
    var oxtString = pac.localPurchasePrice != null
        ? NumberFormat('0.00')
            .format(_pricing?.toOXT(pac.localPurchasePrice ?? 0)
        : '...';
     */

    var enabled = pac.localPurchasePrice != null && _storeOpen == true;

    Gradient grad = VerticalLinearGradient(
        begin: Alignment(0.0, gradBegin),
        end: Alignment(0.0, gradEnd),
        colors: [
          enabled ? Color(0xff4e71c2) : Colors.grey,
          enabled ? Color(0xff258993) : Colors.grey
        ]);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: enabled
          ? () {
              _confirmPurchase(pac: pac);
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: grad,
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top row with title and price
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // left side title usage description
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title,
                            textAlign: TextAlign.left, style: titleStyle),
                      ],
                    ),
                  ),
                  padx(4),

                  // right side title value display
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(children: [
                      Text("${pac.localDisplayPrice ?? '...'}",
                          style:
                              valueStyle.copyWith(fontWeight: FontWeight.bold)),
                      pady(2),
                      /*
                      Visibility(
                        visible: _pricing != null,
                        child:
                            Text("~ $oxtString OXT", style: valueSubtitleStyle),
                      ),
                       */
                    ]),
                  ),
                ],
              ),
              pady(4),

              // bottom tier description text
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(text: subtitle, textAlign: TextAlign.left),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPacPurchaseCard(PAC pac) {
    const valueStyle = TextStyle(
        color: Colors.black,
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.38,
        fontFamily: 'SFProText-Regular',
        height: 25.0 / 20.0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _confirmPurchase(pac: pac);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PAC", style: valueStyle),
              Text("${pac.localDisplayPrice ?? '...'}",
                  style: valueStyle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // TODO:
  TextSpan _buildPurchaseDescriptionText({String text}) {
    const subtitleStyle = TextStyle(
      color: Colors.white,
      fontSize: 12.0,
      height: 16.0 / 12.0,
    );
    var subtitleStyleBold = subtitleStyle.copyWith(fontWeight: FontWeight.bold);
    return TextSpan(
      children: [
        TextSpan(text: text, style: subtitleStyleBold),
      ],
    );
  }

  Future<void> _confirmPurchase({PAC pac}) async {
    var style1 = AppText.dialogBody.copyWith(fontSize: 16);
    var valueStyle = AppText.valueStyle;

    var credits = pac.localPurchasePrice;
    var fee = pac.localPurchasePrice * 0.3;
    var promo = fee;
    var total = credits;

    await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                pady(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            pady(8),
                            Text(
                              "VPN Credits",
                              style: style1,
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              "- Tx Fee",
                              style: style1,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              "- Promo",
                              style: style1,
                              textAlign: TextAlign.right,
                            ),
                            Text(
                              "Total",
                              style: style1,
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    ),
                    padx(24),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          pady(8),
                          // TODO: Localize currency
                          Text(
                            '\$' + formatCurrency(credits),
                            style: valueStyle,
                            textAlign: TextAlign.right,
                          ),
                          Text(
                            '- ' + formatCurrency(fee),
                            style: valueStyle,
                            textAlign: TextAlign.right,
                          ),
                          Text(
                            '+ ' + formatCurrency(promo),
                            style: valueStyle,
                            textAlign: TextAlign.right,
                          ),
                          // TODO: Localize currency
                          Text(
                            '\$' + formatCurrency(total),
                            style: valueStyle,
                            textAlign: TextAlign.right,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                pady(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundedRectButton(
                      text: "Buy",
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        _purchase(purchase: pac);
                      },
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }

  Future<void> _purchase({PAC purchase}) async {
    log("iap: calling purchase: $purchase");

    // TODO: Hard coded for xDAI currently
    var fundingTx = await OrchidEthereumV1().createFundingTransaction(
        signer: widget.signer,
        chain: Chains.xDAI,
        totalUsdValue: purchase.usdPriceApproximate);

    // Add the pending transaction(s) for this purchase
    PacPurchaseTransaction(
      PacAddBalanceTransaction.pending(
          signer: widget.signer, productId: purchase.productId),
      PacSubmitRawTransaction(fundingTx),
    ).save();

    // Initiate the in-app purchase
    try {
      await OrchidPurchaseAPI().purchase(purchase);
    } catch (err) {
      if (err is SKError) {
        var skerror = err;
        if (skerror.code == OrchidPurchaseAPI.SKErrorPaymentCancelled) {
          log("iap: user cancelled");
        }
      }
      log("iap: Error in purchase call: $err");
      await _iapPurchaseError(
          rateLimitExceeded: err is PACPurchaseExceedsRateLimit);
    }

    Navigator.of(context).pop();
  }

  /// An error during the IAP purchase should be resolved here by showing a
  /// dialog and does not leave a pending or error state PAC transaction.
  Future<void> _iapPurchaseError({bool rateLimitExceeded = false}) async {
    log("iap: purchase page: showing error, rateLimitExceeded: $rateLimitExceeded");

    // Clear any error tx
    var tx = await PacTransaction.shared.get();
    if (tx != null && tx.state == PacTransactionState.Error) {
      log("iap: clearing error tx");
      await PacTransaction.shared.clear();
    } else {
      log("iap: purchase error called with incorrect pac tx state");
    }

    return await AppDialogs.showAppDialog(
      context: context,
      title: s.purchaseError,
      bodyText: rateLimitExceeded
          ? s.weAreSorryButThisPurchaseWouldExceedTheDaily
          : s.thereWasAnErrorInPurchasingContact,
    );
  }

  void initProducts() async {
    // Show cached products immediately followed by an update.
    await updateProducts(refresh: false);
    if (mounted) {
      setState(() {});
    }
    await updateProducts(refresh: true);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateProducts({bool refresh}) async {
    if (refresh) {
      log("iap: purchase page refresh products");
    } else {
      log("iap: purchase page fetch cached products");
    }
    try {
      Map<String, PAC> updatedPacs =
          await OrchidPurchaseAPI().requestProducts(refresh: refresh);
      _pacs = updatedPacs.isNotEmpty ? updatedPacs.values.toList() : _pacs;
    } catch (err) {
      log("iap: error requesting products for purchase page: $err");
    }
  }

  @override
  void dispose() {
    _subscriptions.forEach((sub) {
      sub.cancel();
    });
    super.dispose();
    ScreenOrientation.reset();
  }

  S get s {
    return S.of(context);
  }

  bool get _storeOpen {
    return _storeStatus == null || _storeStatus.open;
  }

/*
  bool _productForSale(PAC pac) {
    // default to selling if any ambiguity
    if (_storeStatus == null) {
      return true;
    }
    var status = _storeStatus.product[pac.productId];
    if (status == false) {
      return false;
    }
    return true;
  }
   */
}
