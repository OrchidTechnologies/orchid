import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/purchase/orchid_pac.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';
import 'package:orchid/util/on_off.dart';
import 'package:orchid/util/units.dart';
import 'package:styled_text/styled_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_routes.dart';

enum WelcomePanelState {
  welcome,
  confirm,
  // after hitting confirm wait for processing to begin
  confirm_wait,
  processing_pac,
  processing_chain,
  processing_timeout
}

class WelcomePanel extends StatefulWidget {
  final StoredEthereumKey identity;
  final VoidCallback onDismiss;

  const WelcomePanel({
    Key key,
    @required this.identity,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<WelcomePanel> createState() => _WelcomePanelState();
}

class _WelcomePanelState extends State<WelcomePanel> {
  WelcomePanelState _state;
  PAC _dollarPAC;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    UserPreferences().pacTransaction.stream().listen((tx) {
      if (tx == null) {
        _state = WelcomePanelState.welcome;
      } else {
        switch (tx.state) {
          case PacTransactionState.None:
          case PacTransactionState.Pending:
          case PacTransactionState.Ready:
          case PacTransactionState.InProgress:
          case PacTransactionState.WaitingForRetry:
            _state = WelcomePanelState.processing_pac;
            break;
          case PacTransactionState.WaitingForUserAction:
          case PacTransactionState.Error:
            _state = WelcomePanelState.processing_timeout;
            break;
          case PacTransactionState.Complete:
            _state = WelcomePanelState.processing_chain;
            break;
        }
      }
      setState(() {});
    });

    _dollarPAC = await OrchidPurchaseAPI.getDollarPAC();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.identity == null || _state == null || _dollarPAC == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 28),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          color: Colors.black,
          child: Container(
            color: OrchidColors.dark_background.withOpacity(0.25),
            child: OrchidPanel(
              highlight: true,
              // TODO: Why isn't this animating scaling up?
              // child: AnimatedSize(
              // duration: Duration(milliseconds: 300),
              // alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitle(),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Opacity(
      opacity: 0.99,
      child: Container(
        width: double.infinity,
        height: 50,
        color: Colors.white.withOpacity(0.1),
        child: Center(child: _buildTitleContent()),
      ),
    );
  }

  Widget _buildTitleContent() {
    switch (_state) {
      case WelcomePanelState.welcome:
        return Text(s.welcomeToOrchid).title.height(2.0);
        break;
      case WelcomePanelState.confirm:
      case WelcomePanelState.confirm_wait:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Visibility(
                visible: _state == WelcomePanelState.confirm,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _state = WelcomePanelState.welcome;
                    });
                  },
                  icon: Icon(Icons.chevron_left),
                  color: Colors.white,
                ),
              ),
            ),
            Text(s.fundYourAccount).title.height(2.0),
            Container(width: 48),
          ],
        );
        break;
      case WelcomePanelState.processing_pac:
      case WelcomePanelState.processing_chain:
      case WelcomePanelState.processing_timeout:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 60),
            Text(s.processing).title.height(2.0),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _dismiss();
                  });
                },
                icon: Icon(Icons.close),
                color: Colors.white,
              ),
            ),
          ],
        );
        break;
    }
    throw Exception();
  }

  Widget _buildContent() {
    switch (_state) {
      case WelcomePanelState.welcome:
        return _buildContentWelcomeState();
        break;
      case WelcomePanelState.confirm:
      case WelcomePanelState.confirm_wait:
        return _buildContentConfirmState();
        break;
      case WelcomePanelState.processing_pac:
      case WelcomePanelState.processing_chain:
      case WelcomePanelState.processing_timeout:
        return _buildContentProcessingState();
        break;
    }
    throw Exception();
  }

  Widget _buildContentWelcomeState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pady(32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
                  s.subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService)
              .body2
              .center,
        ),
        pady(40),
        OrchidActionButton(
          enabled: true,
          text: s.getStartedFor1(_dollarPAC?.localDisplayPrice ?? ''),
          onPressed: () {
            setState(() {
              _state = WelcomePanelState.confirm;
            });
          },
        ),
        pady(16),
        _buildOutlineButton(
            text: s.importAccount,
            onPressed: () {
              _importAccount(context);
            }),
        pady(24),
        Text(s.illDoThisLater).linkButton(onTapped: _dismiss),
        pady(40),
      ],
    );
  }

  Widget _buildContentConfirmState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pady(32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StyledText(
            textAlign: TextAlign.center,
            style: OrchidText.body2,
            text: s
                .connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By,
            tags: {
              'link1': OrchidText.linkStyle.link(OrchidUrls.preferredProviders),
            },
          ),
        ),
        pady(40),
        _buildConfirmPurchaseDetails(pac: _dollarPAC),
        pady(40),
        OrchidActionButton(
          enabled: _state == WelcomePanelState.confirm,
          text: s.confirmPurchase,
          onPressed: _doPurchase,
        ),
        pady(24),
        Text(s.illDoThisLater).linkButton(onTapped: _dismiss),
        pady(40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: StyledText(
            textAlign: TextAlign.center,
            style: OrchidText.caption.copyWith(fontSize: 12),
            text: s
                .orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink,
            tags: {
              'link': OrchidText.linkStyle.size(12).link(OrchidUrls.xdaiChain),
            },
          ),
        ),
        pady(40),
      ],
    );
  }

  Widget _buildContentProcessingState() {
    String text;
    switch (_state) {
      case WelcomePanelState.processing_pac:
        text = s.yourPurchaseIsInProgress;
        break;
      case WelcomePanelState.processing_chain:
        text = s.yourPurchaseIsCompleteAndIsNowBeingProcessedBy;
        break;
      case WelcomePanelState.processing_timeout:
        text = s.thisPurchaseIsTakingLongerThanExpectedToProcessAnd;
        break;
      case WelcomePanelState.welcome:
      case WelcomePanelState.confirm:
      case WelcomePanelState.confirm_wait:
        text = '...';
        break;
    }

    bool timeout;
    switch (_state) {
      case WelcomePanelState.processing_pac:
      case WelcomePanelState.processing_chain:
        timeout = false;
        break;
      case WelcomePanelState.processing_timeout:
      case WelcomePanelState.welcome:
      case WelcomePanelState.confirm:
      case WelcomePanelState.confirm_wait:
        timeout = true;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pady(24),
        if (timeout)
          Icon(Icons.error, color: Color(0xFFF88B9F), size: 40)
        else
          OrchidCircularProgressIndicator.smallIndeterminate(
              size: 30, stroke: 4),
        if (!timeout) ...[
          pady(24),
          Text(s.thisMayTakeAMinute).subtitle,
        ],
        pady(24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: StyledText(
            textAlign: TextAlign.center,
            style: OrchidText.caption.copyWith(fontSize: 12),
            text: text,
            tags: {
              'link': OrchidText.linkStyle.size(12).link(OrchidUrls.xdaiChain),
            },
          ),
        ),
        pady(24),
        if (timeout) ...[
          TextButton(
            onPressed: () {
              AppRoutes.pushAccountManager(context);
            },
            child: Text(
              s.manageAccounts.toUpperCase(),
              style: OrchidText.button.tappable,
            ),
          ),
          pady(32),
        ],
      ],
    );
  }

  Widget _buildConfirmPurchaseDetails({@required PAC pac}) {
    if (pac == null) {
      throw Exception("welcome panel: pac null");
    }
    var credits = pac.localPrice;
    var fee = pac.localPrice * 0.3;
    var promo = fee;
    var total = credits;

    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.vpnCredits).body2,
              Text(formatCurrency(credits)).body2,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.blockchainFee).body2,
              Text('+ ' + formatCurrency(fee)).body2,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.promotion, style: OrchidText.body2.blueHightlight),
              Text('- ' + formatCurrency(promo),
                  style: OrchidText.body2.blueHightlight),
            ],
          ),
          pady(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.total.toUpperCase()).subtitle,
              Text(formatCurrency(total)).subtitle,
            ],
          )
        ],
      ),
    );
  }

  void _doPurchase() async {
    if (_dollarPAC == null) {
      return;
    }
    // disable the purchase button, etc.
    setState(() {
      _state = WelcomePanelState.confirm_wait;
    });
    await PurchaseUtils.purchase(
      purchase: _dollarPAC,
      signerKey: widget.identity,
      onError: ({rateLimitExceeded}) async {
        setState(() {
          // This should really be an additional error state
          _state = WelcomePanelState.processing_timeout;
        });
      },
    );
  }

  void _dismiss() {
    widget.onDismiss();
  }

  Widget _buildOutlineButton({
    @required String text,
    VoidCallback onPressed,
  }) {
    Color backgroundColor = OrchidColors.dark_background;
    Color borderColor = OrchidColors.tappable;
    Color textColor = OrchidColors.tappable;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 294,
        height: 52,
        child: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: borderColor, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.all(Radius.circular(16)))),
          onPressed: onPressed,
          child: Text(
            text,
            style: OrchidText.button.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }

  void _importAccount(BuildContext context) async {
    _openAccountManager(context, import: true);
  }

  void _openDapp() async {
    launch(OrchidUrls.accountOrchid, forceSafariVC: false);
  }

  void _openAccountManager(context,
      {bool import = false, bool purchase = false}) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return AccountManagerPage(openToImport: import, openToPurchase: purchase);
    }));
  }

  S get s {
    return S.of(context);
  }
}
