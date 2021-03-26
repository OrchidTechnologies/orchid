import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/api/purchase/orchid_pac_server.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/api/orchid_log_api.dart';
import '../app_text.dart';

class PurchaseStatus extends StatefulWidget {
  const PurchaseStatus({Key key}) : super(key: key);

  @override
  _PurchaseStatusState createState() => _PurchaseStatusState();
}

extension StreamExtensions on StreamSubscription {
  void dispose(List<StreamSubscription> disposal) {
    disposal.add(this);
  }
}

class _PurchaseStatusState extends State<PurchaseStatus> {
  String _statusMessage;
  bool _requiresUserAction = false;
  bool _showHelpExpanded = false;
  bool _showCompleted = false;

  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    (await PacTransaction.shared.streamAsync())
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
      secondChild: _buildStatusContainer(),
    );
  }

  Widget _buildStatusContainer() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: Colors.deepPurple.withOpacity(0.1),
          ),
          padding: EdgeInsets.all(16),
          child: _buildStatus(),
        ),
        if (_showCompleted)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              iconSize: 18,
              icon: Icon(Icons.close),
              onPressed: _dismissCompleted,
            ),
          ),
      ],
    );
  }

  void _dismissCompleted() async {
    print("XXX: dismiss complete");
    var tx = (await PacTransaction.shared.get());
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
    return _requiresUserAction
        ? _buildRequiresUserAction()
        : _buildProgressIndicator();
  }

  // TODO: This message is tailored for the full purchase for this release.
  // TODO: In the future it will need to look at the transaction type.
  Widget _buildCompleted() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          s.transactionSentToBlockchain,
          style: TextStyle(fontSize: 16),
        ),
        pady(8),
        Text(
          s.yourPurchaseIsCompleteAndIsNowBeingProcessedBy,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
        pady(16),
        LinkText(s.copyReceipt,
            style: AppText.linkStyle, onTapped: _copyDebugInfo),
      ],
    );
  }

  Column _buildRequiresUserAction() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          s.pacPurchaseWaiting,
          style: TextStyle(fontSize: 16),
        ),
        pady(16),
        FlatButton(
            color: Colors.deepPurple,
            child: Text(
              s.retry,
              style: TextStyle(color: Colors.white),
            ),
            onPressed: _retryPurchase),
        _showHelpExpanded ? _buildHelpExpanded() : _buildHelp()
      ],
    );
  }

  // The spinner
  Column _buildProgressIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(),
        ),
        pady(12),
        Text(
          _statusMessage ?? "",
          style: TextStyle(fontSize: 16),
        )
      ],
    );
  }

  Column _buildHelp() {
    return Column(
      children: <Widget>[
        pady(8),
        LinkText(s.getHelpResolvingIssue,
            style: AppText.linkStyle, onTapped: _expandHelp),
      ],
    );
  }

  Column _buildHelpExpanded() {
    return Column(
      children: <Widget>[
        pady(12),
        FlatButton(
            color: AppText.linkStyle.color,
            child: Text(s.copyDebugInfo, style: TextStyle(color: Colors.white)),
            onPressed: _copyDebugInfo),
        pady(12),
        LinkText(s.contactOrchid,
            style: AppText.linkStyle, url: 'https://orchid.com/contact'),
        pady(12),
        FlatButton(
            color: Colors.redAccent,
            child: Text(s.remove, style: TextStyle(color: Colors.white)),
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
    PacTransaction tx = await PacTransaction.shared.get();
    Clipboard.setData(
        ClipboardData(text: tx != null ? tx.userDebugString() : '<no tx>'));
  }

  void _retryPurchase() async {
    (await (PacTransaction.shared).get()).ready().save();
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
  void _pacTransactionUpdated(PacTransaction tx) async {
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
        _show(s.retryPurchasedPAC + retry, requiresUserAction: true);
        break;
      case PacTransactionState.Error:
        _show(s.purchaseError, requiresUserAction: true);
        break;
      case PacTransactionState.Complete:
        log("iap: purchase status set complete");
        setState(() {
          _showCompleted = true;
        });
        break;
    }
  }

  void _show(String message, {bool requiresUserAction = false}) {
    log("iap: display message: $message");
    setState(() {
      _statusMessage = message;
      _requiresUserAction = requiresUserAction;
    });
  }

  void _hide() {
    setState(() {
      _statusMessage = null;
      _requiresUserAction = false;
    });
  }

  S get s {
    return S.of(context);
  }

  @override
  void dispose() {
    _subscriptions.forEach((sub) {
      sub.cancel();
    });
    super.dispose();
  }
}
