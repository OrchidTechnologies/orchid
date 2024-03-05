import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_ticket.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';


class ProviderConnection {
  final maxuint256 = BigInt.two.pow(256) - BigInt.one;
  final maxuint64 = BigInt.two.pow(64) - BigInt.one;
  final wei = BigInt.from(10).pow(18);
  var _providerChannel;
  Function onMessage;
  Function onChat;
  Function onConnect;
  Function onError;
  Function onDisconnect;
  Function onSystemMessage;
  Function onInternalMessage;
  EthereumAddress contract;
  String url;
  AccountDetail accountDetail;

  ProviderConnection({required  this.onMessage, required this.onConnect,
                      required this.onChat, required this.onDisconnect, required this.onError,
                      required this.onSystemMessage, required this.onInternalMessage,
                      required this.contract, required this.url, required this.accountDetail, 
                    }) {
    var channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse(url));
      channel.ready;
    } catch (e) {
      onError('Failed on provider connection: $e');
      return;
    }
    _providerChannel = channel;
    _providerChannel.stream.listen(
      receiveProviderMessage,
      onDone: onDisconnect,
      onError: (error) { onError('ws error: $error'); },
    );
    onConnect();
  }

  bool validInvoice(invoice) {
    return invoice.containsKey('amount') && invoice.containsKey('commit') &&
           invoice.containsKey('recipient');
  }

  void payInvoice(Map<String, dynamic> invoice) {
    var payment;
    if (!validInvoice(invoice)) {
      onError('Invalid invoice ${invoice}');
      return;
    }
    assert(accountDetail.funder != null);
    final balance = accountDetail.lotteryPot?.balance.intValue ?? BigInt.zero;
    final deposit = accountDetail.lotteryPot?.deposit.intValue ?? BigInt.zero;
    final faceval = bigIntMin(balance, (wei * deposit) ~/ (wei * BigInt.two));
    final data = BigInt.zero;
    final due = BigInt.parse(invoice['amount']);
    final lotaddr = contract;
    final token = EthereumAddress.zero;
    final ratio = maxuint64 & (maxuint64 * due ~/ faceval);
    final commit = BigInt.parse(invoice['commit'] ?? '0x0');
    final recipient = invoice['recipient'];
    final ticket = OrchidTicket(
      data: data,
      lotaddr: lotaddr,
      token: token,
      amount: faceval,
      ratio: ratio,
      funder: accountDetail.account.funder,
      recipient: EthereumAddress.from(recipient),
      commitment: commit,
      privateKey: accountDetail.account.signerKey.private,
      millisecondsSinceEpoch: 1708638722494,
    );
    payment = '{"type": "payment", "tickets": ["${ticket.serializeTicket()}"]}';
    onInternalMessage('Client: $payment');
    sendProviderMessage(payment);
  }

  void receiveProviderMessage(message) {
    final data = jsonDecode(message) as Map<String, dynamic>;

    print(message);
    onMessage('Provider: $message');

    switch (data['type']) {
      case 'job_complete':
        onChat(data['output'], data);
      case 'invoice':
        payInvoice(data);
      case 'bid_low':
        onSystemMessage("Bid below provider's reserve price.");
    }
  }

  void sendProviderMessage(message) {
    print('Sending message to provider $message');
    _providerChannel.sink.add(message);
  }

  @override
  void dispose() {
    _providerChannel.sink.close;
    onDisconnect();
  }

  BigInt bigIntMin(BigInt a, BigInt b) {
    if (a > b) {
      return b;
    }
    return a;
  }
}
