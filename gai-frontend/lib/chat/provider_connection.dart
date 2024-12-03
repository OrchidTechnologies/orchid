import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_ticket.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'inference_client.dart';
import 'chat_message.dart';

typedef MessageCallback = void Function(String message);
typedef ChatCallback = void Function(
    String message, Map<String, dynamic> metadata);
typedef VoidCallback = void Function();
typedef ErrorCallback = void Function(String error);
typedef AuthTokenCallback = void Function(String token, String inferenceUrl);

class _PendingRequest {
  final String requestId;
  final String modelId;
  final List<ChatMessage> messages;
  final Map<String, Object>? params;
  final DateTime timestamp;

  _PendingRequest({
    required this.requestId,
    required this.modelId,
    required this.messages,
    required this.params,
  }) : timestamp = DateTime.now();
}

class ProviderConnection {
  final maxuint256 = BigInt.two.pow(256) - BigInt.one;
  final maxuint64 = BigInt.two.pow(64) - BigInt.one;
  final wei = BigInt.from(10).pow(18);
  WebSocketChannel? _providerChannel;

  InferenceClient? get inferenceClient => _inferenceClient;
  InferenceClient? _inferenceClient;
  final MessageCallback onMessage;
  final ChatCallback onChat;
  final VoidCallback onConnect;
  final ErrorCallback onError;
  final VoidCallback onDisconnect;
  final MessageCallback onSystemMessage;
  final MessageCallback onInternalMessage;
  final EthereumAddress? contract;
  final String url;
  final String? authToken;
  final AccountDetail? accountDetail;
  final AuthTokenCallback? onAuthToken;
  final Map<String, String> _requestModels = {};
  final Map<String, _PendingRequest> _pendingRequests = {};
  bool _usingDirectAuth = false;

  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
  }

  ProviderConnection({
    required this.onMessage,
    required this.onConnect,
    required this.onChat,
    required this.onDisconnect,
    required this.onError,
    required this.onSystemMessage,
    required this.onInternalMessage,
    this.contract,
    required this.url,
    this.accountDetail,
    this.authToken,
    this.onAuthToken,
  }) {
    _usingDirectAuth = authToken != null;

    if (!_usingDirectAuth) {
      try {
        _providerChannel = WebSocketChannel.connect(Uri.parse(url));
        _providerChannel?.ready;
      } catch (e) {
        onError('Failed on provider connection: $e');
        return;
      }
      _providerChannel?.stream.listen(
        receiveProviderMessage,
        onDone: () => onDisconnect(),
        onError: (error) => onError('ws error: $error'),
      );
    } else {
      // Set up inference client directly with auth token
      _inferenceClient = InferenceClient(baseUrl: url);
      _inferenceClient!.setAuthToken(authToken!);
      onInternalMessage('Using direct auth token');
    }
    onConnect();
  }

  static Future<ProviderConnection> connect({
    required String billingUrl,
    required String inferenceUrl,
    EthereumAddress? contract,
    AccountDetail? accountDetail,
    String? authToken,
    required MessageCallback onMessage,
    required ChatCallback onChat,
    required VoidCallback onConnect,
    required ErrorCallback onError,
    required VoidCallback onDisconnect,
    required MessageCallback onSystemMessage,
    required MessageCallback onInternalMessage,
    AuthTokenCallback? onAuthToken,
  }) async {
    if (authToken == null && accountDetail == null) {
      throw Exception('Either authToken or accountDetail must be provided');
    }

    final connection = ProviderConnection(
      onMessage: onMessage,
      onConnect: onConnect,
      onChat: onChat,
      onDisconnect: onDisconnect,
      onError: onError,
      onSystemMessage: onSystemMessage,
      onInternalMessage: onInternalMessage,
      contract: contract,
      url: authToken != null ? inferenceUrl : billingUrl,
      accountDetail: accountDetail,
      authToken: authToken,
      onAuthToken: onAuthToken,
    );

    return connection;
  }

  void _handleAuthToken(Map<String, dynamic> data) {
    final token = data['session_id'];
    final inferenceUrl = data['inference_url'];
    if (token == null || inferenceUrl == null) {
      onError('Invalid auth token response');
      return;
    }

    _inferenceClient = InferenceClient(baseUrl: inferenceUrl);
    _inferenceClient!.setAuthToken(token);
    onInternalMessage('Auth token received and inference client initialized');

    onAuthToken?.call(token, inferenceUrl);
  }

  bool validInvoice(invoice) {
    return invoice.containsKey('amount') &&
        invoice.containsKey('commit') &&
        invoice.containsKey('recipient');
  }

  void payInvoice(Map<String, dynamic> invoice) {
    if (_usingDirectAuth) {
      onError('Unexpected invoice received while using direct auth token');
      return;
    }

    var payment;
    if (!validInvoice(invoice)) {
      onError('Invalid invoice ${invoice}');
      return;
    }

    assert(accountDetail?.funder != null);
    final balance = accountDetail?.lotteryPot?.balance.intValue ?? BigInt.zero;
    final deposit = accountDetail?.lotteryPot?.deposit.intValue ?? BigInt.zero;

    if (balance <= BigInt.zero || deposit <= BigInt.zero) {
      onError('Insufficient funds: balance=$balance, deposit=$deposit');
      return;
    }

    final faceval = _bigIntMin(balance, (wei * deposit) ~/ (wei * BigInt.two));
    if (faceval <= BigInt.zero) {
      onError('Invalid face value: $faceval');
      return;
    }

    final data = BigInt.zero;
    final due = BigInt.from(invoice['amount']);
    final lotaddr = contract;
    final token = EthereumAddress.zero;

    BigInt ratio;
    try {
      ratio = maxuint64 & (maxuint64 * due ~/ faceval);
    } catch (e) {
      onError('Failed to calculate ratio: $e (due=$due, faceval=$faceval)');
      return;
    }

    final commit = BigInt.parse(invoice['commit'] ?? '0x0');
    final recipient = invoice['recipient'];

    final ticket = OrchidTicket(
      data: data,
      lotaddr: lotaddr!,
      token: token,
      amount: faceval,
      ratio: ratio,
      funder: accountDetail!.account.funder,
      recipient: EthereumAddress.from(recipient),
      commitment: commit,
      privateKey: accountDetail!.account.signerKey.private,
      millisecondsSinceEpoch: DateTime.now().millisecondsSinceEpoch,
    );

    payment = '{"type": "payment", "tickets": ["${ticket.serializeTicket()}"]}';
    onInternalMessage('Client: $payment');
    _sendProviderMessage(payment);
  }

  void receiveProviderMessage(dynamic message) {
    final data = jsonDecode(message) as Map<String, dynamic>;
    print(message);
    onMessage('Provider: $message');

    switch (data['type']) {
      case 'job_complete':
        final requestId = data['request_id'];
        final pendingRequest =
            requestId != null ? _pendingRequests.remove(requestId) : null;

        onChat(data['output'], {
          ...data,
          'model_id': pendingRequest?.modelId,
        });
        break;
      case 'invoice':
        payInvoice(data);
        break;
      case 'bid_low':
        onSystemMessage("Bid below provider's reserve price.");
        break;
      case 'auth_token':
        _handleAuthToken(data);
        break;
    }
  }

  Future<void> requestAuthToken() async {
    if (_usingDirectAuth) {
      onError('Cannot request auth token when using direct auth');
      return;
    }

    final message = '{"type": "request_token"}';
    onInternalMessage('Requesting auth token');
    _sendProviderMessage(message);
  }

  Future<void> requestInference(
    String modelId,
    List<ChatMessage> messages, {
    Map<String, Object>? params,
  }) async {
    if (!_usingDirectAuth && _inferenceClient == null) {
      await requestAuthToken();
      await Future.delayed(Duration(milliseconds: 100));

      if (_inferenceClient == null) {
        onError('No inference connection available');
        return;
      }
    }

    try {
      final requestId = _generateRequestId();

      _pendingRequests[requestId] = _PendingRequest(
        requestId: requestId,
        modelId: modelId,
        messages: messages,
        params: params,
      );

      final allParams = {
        ...?params,
        'request_id': requestId,
      };

      onInternalMessage('Sending inference request:\n'
          'Model: $modelId\n'
          'Messages: ${messages.map((m) => "${m.source}: ${m.message}").join("\n")}\n'
          'Params: $allParams');

      final result = await _inferenceClient!.inference(
        messages: messages,
        model: modelId,
        params: allParams,
      );

      final pendingRequest = _pendingRequests.remove(requestId);

      onChat(result['response'], {
        'type': 'job_complete',
        'output': result['response'],
        'usage': result['usage'],
        'model_id': pendingRequest?.modelId,
        'request_id': requestId,
        'estimated_prompt_tokens': result['estimated_prompt_tokens'],
      });
    } catch (e, stack) {
      onError('Failed to send inference request: $e\n$stack');
    }
  }

  void _sendProviderMessage(String message) {
    if (_usingDirectAuth) {
      onError('Cannot send provider message when using direct auth');
      return;
    }
    print('Sending message to provider $message');
    _providerChannel?.sink.add(message);
  }

  void dispose() {
    _providerChannel?.sink.close();
    _pendingRequests.clear();
    onDisconnect();
  }

  BigInt _bigIntMin(BigInt a, BigInt b) {
    if (a > b) {
      return b;
    }
    return a;
  }
}
