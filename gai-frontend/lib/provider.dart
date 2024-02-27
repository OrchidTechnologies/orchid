import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_ticket.dart';


class ProviderConnection {
  List<String> providers = [];
  int _providerIndex = 0;
  var _providerChannel;
  Function onMessage;
  Function onChat;
  Function onConnect;
  Function onError;
  Function onDisconnect;
  Function onSystemMessage;
  Function onInternalMessage;
  EthereumAddress contract;
  BigInt signerKey;
  EthereumAddress funder;
  var _faceValue = BigInt.from(50000000000000000);

  
  ProviderConnection({required this.providers, required  this.onMessage, required this.onConnect,
                      required this.onChat, required this.onDisconnect, required this.onError,
                      required this.onSystemMessage, required this.onInternalMessage, funder, signerKey,
                      required this.contract, })
                      : this.funder = funder ?? '',
                        this.signerKey = signerKey ?? '';

  void connectProvider() async {
    if (_providerChannel != null) {
      await _providerChannel.sink.close;
      onDisconnect();
      _providerChannel = null;
    }
    var url = lookupProvider();
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

  String lookupProvider() {
    if (providers.length > 0) {
      _providerIndex = (_providerIndex + 1) % providers.length;
      return providers[_providerIndex];
    }
    return '';
  }

  void payInvoice(Map<String, dynamic> invoice) {
    var payment;
    final data = BigInt.zero;
    final due = invoice['amount'];
    final lotaddr = contract;
    final token = EthereumAddress.zero;
    final ratio = BigInt.parse('9223372036854775808');
    final commit = BigInt.parse(invoice['commit'] ?? '0x0');
    final recipient = invoice['recipient'] ?? '0x0';
    final ticket = OrchidTicket(
      data: data,
      lotaddr: lotaddr,
      token: token,
      amount: _faceValue,
      ratio: ratio,
      funder: funder,
      recipient: EthereumAddress.from(recipient),
      commitment: commit,
      privateKey: signerKey,
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
}
