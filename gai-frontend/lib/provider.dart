import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_ticket.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';


class ProviderConnection {
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
  var _faceValue = BigInt.from(50000000000000000);

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

  void payInvoice(Map<String, dynamic> invoice) {
    var payment;
    assert(invoice.containsKey('recipient'));
    assert(accountDetail.funder != null);
    final data = BigInt.zero;
    final due = invoice['amount'];
    final lotaddr = contract;
    final token = EthereumAddress.zero;
    final ratio = BigInt.parse('9223372036854775808');
    final commit = BigInt.parse(invoice['commit'] ?? '0x0');
    final recipient = invoice['recipient'];
    final ticket = OrchidTicket(
      data: data,
      lotaddr: lotaddr,
      token: token,
      amount: _faceValue,
      ratio: ratio,
      funder: accountDetail.account.funder, // ?? EthereumAddress.zero,
      recipient: EthereumAddress.from(recipient),
      commitment: commit,
      privateKey: accountDetail.account.signerKey.private,
      millisecondsSinceEpoch: 1708638722494,
    );
    ticket.printTicket();
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
}
