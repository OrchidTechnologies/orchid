import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/purchase/orchid_pac.dart';
import 'package:orchid/api/purchase/orchid_pac_seller.dart';
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:orchid/util/units.dart';
import 'package:styled_text/styled_text.dart';
import '../app_colors.dart';
import '../app_sizes.dart';
import '../app_text.dart';

typedef PurchasePageCompletion = void Function(); // TODO: return

class PurchasePage extends StatefulWidget {
  final StoredEthereumKey signerKey;
  final PurchasePageCompletion completion;
  final bool cancellable; // show the close button instead of a back arrow

  const PurchasePage(
      {Key key,
      @required this.signerKey,
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
  bool _storeMessageDimissed = false;
  USD _bandwidthPrice;

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

    _bandwidthPrice = await OrchidEthereumV1.getBandwidthPrice();
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
                      _buildTopText(),
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
          if (_storeDown || _showStoreMessage) _buildStoreMessage()
        ],
      ),
    );
  }

  Widget _buildStoreMessage() {
    Size size = MediaQuery.of(context).size;
    var text = _storeStatus?.message != null
        ? _storeStatus.message
        : s.theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn;
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
                        text,
                        style: TextStyle(color: Colors.black, fontSize: 14.0),
                      ),
                      pady(8),
                      LinkText(
                        s.seeOrchidcomForHelp,
                        overflow: TextOverflow.visible,
                        style: AppText.linkStyle.copyWith(fontSize: 12.0),
                        url: 'https://orchid.com/help',
                      ),
                      if (_storeUp)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RoundedRectButton(
                                text: s.ok,
                                onPressed: () {
                                  setState(() {
                                    _storeMessageDimissed = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
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

  Widget _buildTopText() {
    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
      fontFamily: 'SFProText-Semibold',
    );

    var payPerUse = s.payPerUseVpnService;
    var price = _bandwidthPrice != null
        ? "\$" + formatCurrency(_bandwidthPrice.value)
        : "...";
    var currentAvgVPNPrice = s.currentAvgVpnPriceIsPricePerGb(price);
    var notASub = s.notASubscriptionCreditsDontExpire;
    var shareAccountWith = s.shareAccountWithUnlimitedDevices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(payPerUse, style: titleStyle),
        pady(16),
        _buildCheckRow(currentAvgVPNPrice),
        pady(8),
        _buildCheckRow(notASub),
        pady(8),
        _buildCheckRow(shareAccountWith),
        pady(12),
      ],
    );
  }

  Widget _buildPreferredProviderText() {
    var bodyStyle = TextStyle(
      // color: Colors.black,
      fontSize: 15,
      fontStyle: FontStyle.italic,
    );
    var linkStyle = AppText.linkStyle.copyWith(
      fontSize: 15.0,
      fontStyle: FontStyle.italic,
    );
    return StyledText(
      style: bodyStyle,
      text: s.purchasedCreditAccountsConnectExclusively +
          '  ' +
          s.allPurchasedAccountsUseThe,
      styles: {
        'link1': linkStyle.link(OrchidUrls.preferredProviders),
        'link2': linkStyle.link(OrchidUrls.xdaiChain),
      },
    );
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
      return LoadingIndicator(height: 50, text: s.noPacsAvailableAtThisTime);
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
    var pacTier4 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier4';
    var pacTier10 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier10';
    var pacTier11 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier11';
    var pac1 = _pacs.firstWhere((pac) => pac.productId == pacTier4);
    var pac2 = _pacs.firstWhere((pac) => pac.productId == pacTier10);
    var pac3 = _pacs.firstWhere((pac) => pac.productId == pacTier11);

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

    var enabled = pac.localPrice != null && _storeUp == true;

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

    var credits = pac.localPrice;
    var fee = pac.localPrice * 0.3;
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
                          Text(
                            pac.localDisplayPrice,
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
                          Text(
                            pac.formatCurrency(total),
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
    var fundingTx = await OrchidPacSeller.defaultFundingTransactionParams(
        signerKey: widget.signerKey,
        chain: Chains.xDAI,
        totalUsdValue: purchase.usdPriceExact);

    var signer = widget.signerKey.address;
    // Add the pending transaction(s) for this purchase
    PacPurchaseTransaction(
            PacAddBalanceTransaction.pending(
                signer: signer, productId: purchase.productId),
            fundingTx)
        .save();

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
    if ((tx != null && tx.state == PacTransactionState.Error) ||
        rateLimitExceeded) {
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

  // return up if not null
  bool get _storeUp {
    return _storeStatus != null && _storeStatus.open;
  }

  // return down if not null
  bool get _storeDown {
    return _storeStatus != null && !_storeStatus.open;
  }

  bool get _showStoreMessage {
    return _storeStatus?.message != null && !_storeMessageDimissed;
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
