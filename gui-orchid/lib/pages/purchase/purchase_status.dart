import 'package:orchid/orchid/orchid.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/vpn/purchase/orchid_pac_server.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';
import 'package:orchid/common/app_buttons_deprecated.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/link_text.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';

class PurchaseStatus extends StatefulWidget {
  const PurchaseStatus({Key? key}) : super(key: key);

  @override
  _PurchaseStatusState createState() => _PurchaseStatusState();
}

class _PurchaseStatusState extends State<PurchaseStatus> {
  // The status message to be shown to the user
  String? _statusMessage;

  // If true show the expandable help section
  bool _waitingForUserAction = false;

  // If true the user action should present the retry button
  bool _userActionRetryable = false;

  // If true the user has expanded the help section
  bool _showHelpExpanded = false;

  // If true show the transaction completed status
  bool _showCompleted = false;

  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    PacTransaction.shared
        .stream()
        .listen(_pacTransactionUpdated)
        .dispose(_subscriptions);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: Duration(milliseconds: 300),
      // todo: clean this up
      crossFadeState: _statusMessage == null && !_showCompleted
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild:
          // Container(width: double.infinity, height: 0, color: Colors.green),
          Container(height: 0),
      secondChild: Padding(
        // extra padding that only exists when the status is showing
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildStatusContainer(),
      ),
    );
  }

  Widget _buildStatusContainer() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: OrchidColors.dark_background,
          ),
          padding: EdgeInsets.all(16),
          child: _buildStatus(),
        ),
        if (_showCompleted)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              iconSize: 18,
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: _dismissCompleted,
            ),
          ),
      ],
    );
  }

  void _dismissCompleted() async {
    var tx = (PacTransaction.shared.get());
    if (tx != null && tx.state != PacTransactionState.Complete) {
      throw Exception("not completed");
    }
    if (tx != null) {
      await _deleteTransaction();
    }
    setState(() {
      _showCompleted = false;
    });
  }

  Widget _buildStatus() {
    if (_showCompleted) {
      return _buildCompleted();
    }
    return _waitingForUserAction
        ? _buildRequiresUserAction()
        : _buildProgressIndicator();
  }

  Widget _buildCompleted() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          s.transactionSentToBlockchain,
          textAlign: TextAlign.center,
        ).body1.padx(16),
        pady(8),
        Text(
          s.yourPurchaseIsCompleteAndIsNowBeingProcessedBy,
          textAlign: TextAlign.center,
        ).caption,
        pady(16),
        TextButton(
            onPressed: _copyDebugInfo,
            child: Text(
              s.copyReceipt,
              style: OrchidText.linkStyle,
            )),
      ],
    );
  }

  Column _buildRequiresUserAction() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _userActionRetryable ? s.pacPurchaseWaiting : s.purchaseError,
          style: OrchidText.body2,
        ),
        pady(16),
        if (_userActionRetryable)
          FlatButtonDeprecated(
              color: OrchidColors.purple_ff8c61e1,
              child: Text(
                s.retry.toUpperCase(),
                style: OrchidText.button,
              ),
              onPressed: _retryPurchase),
        pady(8),
        _showHelpExpanded ? _buildHelpExpanded() : _buildHelp()
      ],
    );
  }

  // The spinner
  Column _buildProgressIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OrchidCircularProgressIndicator.smallIndeterminate(size: 22),
        pady(16),
        Text(
          _statusMessage ?? "",
          style: OrchidText.body1,
        )
      ],
    );
  }

  Column _buildHelp() {
    return Column(
      children: <Widget>[
        pady(8),
        LinkText(s.getHelpResolvingIssue,
            style: OrchidText.body1.linkStyle, onTapped: _expandHelp),
      ],
    );
  }

  Column _buildHelpExpanded() {
    return Column(
      children: <Widget>[
        pady(12),
        FlatButtonDeprecated(
          color: OrchidColors.purple_ff8c61e1,
          child: Text(s.copyDebugInfo.toUpperCase()).button,
          onPressed: _copyDebugInfo,
        ),
        pady(12),
        LinkText(s.contactOrchid,
            style: OrchidText.linkStyle, url: 'https://orchid.com/contact'),
        pady(12),
        FlatButtonDeprecated(
            color: Colors.redAccent,
            child: Text(s.remove.toUpperCase()).button,
            onPressed: _confirmDeleteTransaction),
      ],
    );
  }

  void _expandHelp() {
    setState(() {
      _showHelpExpanded = true;
    });
  }

  void _copyDebugInfo() async {
    log("iap: Copy debug info");
    PacTransaction? tx = PacTransaction.shared.get();
    Clipboard.setData(ClipboardData(
        text: tx != null ? (await tx.userDebugString()) : '<no tx>'));
  }

  void _retryPurchase() async {
    log("iap: User hit retry button.");
    ((PacTransaction.shared).get())?.ready().save();
    OrchidPACServer().advancePACTransactions();
  }

  void _confirmDeleteTransaction() {
    AppDialogs.showConfirmationDialog(
        context: context,
        title: s.deleteTransaction,
        bodyText:
            s.clearThisInProgressTransactionExplain + " " + OrchidUrls.contact,
        commitAction: _deleteTransaction);
  }

  Future<void> _deleteTransaction() async {
    return await PacTransaction.shared.clear();
  }

  // Respond to updates of the PAC transaction status
  void _pacTransactionUpdated(PacTransaction? tx) async {
    if (tx == null) {
      _hide();
      return;
    }
    switch (tx.state) {
      case PacTransactionState.None:
        break;
      case PacTransactionState.Pending:
      case PacTransactionState.Ready:
        _show(s.preparingPurchase);
        break;
      case PacTransactionState.InProgress:
        _show(s.talkingToPacServer);
        break;
      case PacTransactionState.WaitingForRetry:
        _show(s.retryingPurchasedPAC);
        break;
      case PacTransactionState.WaitingForUserAction:
        var retry = tx.retries > 0 ? " (${tx.retries})" : "";
        var retryWouldFail = (tx is ReceiptTransaction) && tx.receipt == null;
        _show(
          s.retryPurchasedPAC + retry,
          waitingForUserAction: true,
          userActionRetryable: !retryWouldFail,
        );
        break;
      case PacTransactionState.Error:
        _show(s.purchaseError,
            waitingForUserAction: true, userActionRetryable: false);
        break;
      case PacTransactionState.Complete:
        log("iap: purchase status set complete");
        setState(() {
          _showCompleted = true;
        });
        break;
    }
  }

  void _show(String message,
      {bool waitingForUserAction = false, bool userActionRetryable = true}) {
    log("iap: display message: $message");
    setState(() {
      _statusMessage = message;
      _waitingForUserAction = waitingForUserAction;
      _userActionRetryable = userActionRetryable;
    });
  }

  void _hide() {
    setState(() {
      _statusMessage = null;
      _waitingForUserAction = false;
    });
  }

  @override
  void dispose() {
    _subscriptions.forEach((sub) {
      sub.cancel();
    });
    super.dispose();
  }
}
