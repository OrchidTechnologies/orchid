

class ChatModel extends ChangeNotifier {
  void _startProviderIsolate() async {
    await Isolate.spawn(_handleProvider, _providerPort.sendPort);
  }

  static void _handleProvider(SendPort sendPort) async {
     final wsUrl = Uri.parse('ws://192.168.66.20:8001');
     final channel = WebSocketChannel.connect(wsUrl);
     IsolateChannel appChannel = new IsolateChannel.connectSend(sendPort);

     await channel.ready;

     appChannel.stream.listen((message) {
       channel.sink.add(message);
     });
     print('_handleProvider: connected!');
     channel.stream.listen((message) {
       commslog.add(message);
       appChannel.sink.add(message);
     });
  }

  void sendPrompt(String prompt) {
    _providerChannel.sink.add('{"type": "job", "bid": 0.001, "prompt": "$prompt"}');
  }
  
}
