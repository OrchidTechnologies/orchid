import 'package:orchid/api/orchid_eth/v1/orchid_eth_bandwidth_pricing.dart';
import 'package:orchid/orchid/orchid.dart';
import 'dart:async';
import 'package:orchid/vpn/orchid_api_mock.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/vpn/purchase/ios_purchase.dart';
import 'package:orchid/vpn/purchase/orchid_pac.dart';
import 'package:orchid/vpn/purchase/orchid_pac_seller.dart';
import 'package:orchid/vpn/purchase/orchid_pac_server.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';
import 'package:orchid/vpn/purchase/orchid_purchase.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/common/app_buttons_deprecated.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/link_text.dart';
import 'package:orchid/common/loading.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/util/format_currency.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:styled_text/styled_text.dart';
import '../../common/app_sizes.dart';
import '../../common/app_text.dart';

typedef PurchasePageCompletion = void Function(); // TODO: return

class PurchasePage extends StatefulWidget {
  final StoredEthereumKey? signerKey;
  final PurchasePageCompletion completion;
  final bool cancellable; // show the close button instead of a back arrow

  const PurchasePage(
      {Key? key,
      required this.signerKey,
      required this.completion,
      this.cancellable = false})
      : super(key: key);

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  List<StreamSubscription> _subscriptions = [];
  PACStoreStatus? _storeStatus;
  List<PAC>? _pacs;
  bool _storeMessageDimissed = false;
  USD? _bandwidthPrice;

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

    _bandwidthPrice = await OrchidBandwidthPricing.getBandwidthPrice();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: s.buyCredits,
      child: buildPage(context),
      lightTheme: false,
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
                      if (AppSize(context)
                          .tallerThan(AppSize.iphone_12_pro_max))
                        pady(64),
                      pady(12),
                      _buildTopText(),
                      pady(16),
                      _buildPacList(),
                      pady(24),
                      _buildBottomText()
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
        ? _storeStatus!.message
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
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
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

  var checkRowStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 15.0,
      height: 20.0 / 15.0,
      letterSpacing: -0.24);

  Widget _buildTopText() {
    final titleStyle = OrchidText.medium_24_050;
    var payPerUse = s.payPerUseVpnService;
    var price = (_bandwidthPrice != null && !MockOrchidAPI.hidePrices)
        ? "\$" + formatCurrency(_bandwidthPrice!.value, locale: context.locale)
        : "...";
    var currentAvgVPNPrice = s.averagePriceIsUSDPerGb(price);
    var notASub = s.notASubscriptionCreditsDontExpire;
    var shareAccountWith = s.shareAccountWithUnlimitedDevices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(payPerUse, style: titleStyle),
        pady(27),
        _buildIconRow(
          OrchidAsset.svg.price,
          currentAvgVPNPrice,
        ),
        pady(8),
        _buildIconRow(
          OrchidAsset.svg.access_time,
          notASub,
        ),
        pady(8),
        _buildIconRow(
          OrchidAsset.svg.share,
          shareAccountWith,
        ),
        pady(12),
      ],
    );
  }

  Row _buildIconRow(Widget icon, String text) {
    return Row(
      children: [
        icon,
        padx(16),
        Flexible(
            child: RichText(
                text: TextSpan(
                    text: text,
                    style: OrchidText.regular_14.copyWith(height: 1.4)),
                maxLines: 2)),
      ],
    );
  }

  Widget _buildBottomText() {
    final bodyStyle = OrchidText.caption
        .copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 18 / 12);
    final linkStyle = OrchidText.linkStyle.copyWith(fontSize: 12);

    return StyledText(
      style: bodyStyle,
      text: s.orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre +
          ' ' +
          s.purchasedAccountsConnectExclusivelyToOur +
          ' ' +
          s.refundPolicyCoveredByAppStores,
      tags: {
        'link1': linkStyle.link(OrchidUrls.preferredProviders),
        'link2': linkStyle.link(OrchidUrls.xdaiChain),
      },
    );
  }

  Widget _buildPacList() {
    // var linkStyle = AppText.linkStyle.copyWith(fontSize: 15.0);
    var linkStyle = OrchidText.linkStyle;
    var unavailableText = StyledText(
      style: OrchidText.body1.copyWith(color: OrchidColors.blue_highlight),
      newLineAsBreaks: true,
      text: s.orchidIsUnableToDisplayInappPurchasesAtThisTime +
          '  ' +
          (OrchidPlatform.isApple
              // Duplication here is to allow for better localization
              ? s.pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor
              : s.pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized),
      tags: {
        'link': linkStyle
            .copyWith(fontStyle: FontStyle.italic)
            .link(OrchidUrls.accountOrchid),
      },
    );

    if (_pacs == null) {
      return LoadingIndicator(height: 50);
    }
    if (_pacs!.isEmpty) {
      return unavailableText;
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildFixedPacList()
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
  List<Widget> _buildFixedPacList() {
    if (_pacs == null || _pacs!.isEmpty || _pacs!.length < 3) {
      log("iap: pacs not ready: $_pacs");
      return [];
    }

    // TODO: Hard-coded expected ids
    var pac1 = OrchidPurchaseAPI.pacForTier(_pacs!, 4);
    var pac2 = OrchidPurchaseAPI.pacForTier(_pacs!, 10);
    var pac3 = OrchidPurchaseAPI.pacForTier(_pacs!, 11);

    return [
      _buildPurchaseCardView(
        pac: pac1,
        title: s.gbApproximately12,
        subtitle: _buildPurchaseDescriptionText(
          text: s.goodForBrowsingAndLightActivity,
        ),
      ),
      pady(24),
      _buildHighlightedPurchaseCardView(
        pac: pac2,
        title: s.gbApproximately60,
        subtitle: _buildPurchaseDescriptionText(
          text: s.idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd,
        ),
        highlightText: s.mostPopular,
      ),
      pady(24),
      _buildPurchaseCardView(
        pac: pac3,
        title: s.gbApproximately240,
        subtitle: _buildPurchaseDescriptionText(
            text: s.bandwidthheavyLongtermUsageOrSharedAccounts),
      ),
    ];
  }

  Widget _buildHighlightedPurchaseCardView({
    required PAC pac,
    required String title,
    required TextSpan subtitle,
    required String highlightText,
  }) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: _buildPurchaseCardView(
            pac: pac,
            title: title,
            subtitle: subtitle,
            highlight: true,
            bottomPad: 28,
          ),
        ),
        Container(
            width: 150,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: OrchidGradients.pinkBlueGradientTLBR,
            ),
            child: Center(
                child: Text(s.mostPopular,
                    style: OrchidText.body1.black
                        .copyWith(letterSpacing: 0.02, height: 1.7))))
      ],
    );
  }

  Widget _buildPurchaseCardView({
    required PAC pac,
    required String title,
    required TextSpan subtitle,
    bool highlight = false,
    double bottomPad = 16,
  }) {
    const titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 17.0,
      fontWeight: FontWeight.w700,
    );

    const valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 18.0,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.38,
      fontFamily: 'SFProText-Regular',
    );

    // var enabled = pac.localPrice != null && _storeUp == true;
    var enabled = _storeUp == true;
    var price =
        (MockOrchidAPI.hidePrices ? null : pac.localDisplayPrice) ?? '...';

    return TextButton(
      onPressed: enabled
          ? () {
              _confirmPurchase(pac: pac);
            }
          : null,
      child: OrchidPanel(
        highlight: highlight,
        child: Padding(
          padding:
              EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomPad),
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
                      Text(price,
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

              // bottom description text
              RichText(text: subtitle, textAlign: TextAlign.left)
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildPurchaseDescriptionText({required String text}) {
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

  // TODO: See the alternate impl in the welcome pane
  // TODO: Rework this dialog to clean up formatting complexity and add
  // TODO: a standard close button somehow.
  Future<void> _confirmPurchase({required PAC pac}) async {
    var style1 =
        OrchidText.medium_18_025.copyWith(height: 1.6); // heights should match
    var valueStyle = OrchidText.button.copyWith(height: 1.6);

    var credits = pac.localPrice;
    var fee = pac.localPrice * 0.3;
    var promo = fee;
    var total = credits;

    await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.confirmPurchase).title,
                Container(
                  width: 20,
                  child: FlatButtonDeprecated(
                    padding: EdgeInsets.zero,
                    child: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            backgroundColor: OrchidColors.dark_background,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            pady(16),
                            Text(
                              s.vpnCredits,
                              style: style1,
                            ).body2,
                            pady(13),
                            Text(
                              s.txFee,
                              style: style1,
                            ).body2,
                            pady(13),
                            Text(
                              s.promotion,
                              style: style1,
                            ).body2,
                            pady(20),
                            Text(
                              s.total.toUpperCase(),
                              style: OrchidText.button,
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
                            '+ ' + formatCurrency(fee, locale: context.locale),
                            style: valueStyle,
                            textAlign: TextAlign.right,
                          ),
                          Text(
                            '- ' + formatCurrency(promo, locale: context.locale),
                            style: valueStyle,
                            textAlign: TextAlign.right,
                          ),
                          pady(16),
                          Text(
                            pac.formatCurrency(total),
                            style: valueStyle.bold,
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
                      text: s.buy,
                      textColor: Colors.black,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        _purchase(pac: pac);
                      },
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }

  Future<void> _purchase({required PAC pac}) async {
    if (widget.signerKey == null) {
      return;
    }
    await PurchaseUtils.purchase(
      purchase: pac,
      signerKey: widget.signerKey!,
      onError: _iapPurchaseError,
    );
    Navigator.of(context).pop();
  }

  /// An error during the IAP purchase should be resolved here by showing a
  /// dialog and does not leave a pending or error state PAC transaction.
  Future<void> _iapPurchaseError({bool rateLimitExceeded = false}) async {
    log("iap: purchase page: showing error, rateLimitExceeded: $rateLimitExceeded");

    // Clear any error tx
    var tx = PacTransaction.shared.get();
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

  Future<void> updateProducts({required bool refresh}) async {
    if (refresh) {
      log("iap: purchase page refresh products");
    } else {
      log("iap: purchase page fetch cached products");
    }
    try {
      Map<String, PAC> updatedPacs =
          await OrchidPurchaseAPI().requestProducts(refresh: refresh);
      _pacs = updatedPacs.isNotEmpty ? updatedPacs.values.toList() : [];
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

  // return up if not null
  bool get _storeUp {
    return _storeStatus != null && _storeStatus!.open;
  }

  // return down if not null
  bool get _storeDown {
    return _storeStatus != null && !_storeStatus!.open;
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

class PurchaseUtils {
  static Future<void> purchase({
    required PAC purchase,
    required StoredEthereumKey signerKey,
    required Future<void> Function({required bool rateLimitExceeded}) onError,
  }) async {
    log("iap: calling purchase: $purchase");

    // TODO: Hard coded for xDAI currently
    var fundingTx = await OrchidPacSeller.defaultFundingTransactionParams(
        signerKey: signerKey,
        chain: Chains.Gnosis,
        totalUsdValue: purchase.usdPriceExact);

    var signer = signerKey.address;
    // Add the pending transaction(s) for this purchase
    await PacPurchaseTransaction(
            PacAddBalanceTransaction.pending(
                signer: signer, productId: purchase.productId),
            fundingTx)
        .save();

    // Initiate the in-app purchase
    try {
      await OrchidPurchaseAPI().purchase(purchase);
    } catch (err) {
      // TODO: Is this still possible?
      if (err is SKError) {
        var skerror = err;
        if (skerror.code == IOSOrchidPurchaseAPI.SKErrorPaymentCancelled) {
          log("iap: payment cancelled error, purchase page");
        }
      }
      log("iap: Error in purchase call: $err");
      await onError(rateLimitExceeded: err is PACPurchaseExceedsRateLimit);
    }
  }
}
