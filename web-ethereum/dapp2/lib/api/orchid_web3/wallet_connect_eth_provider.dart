@JS()
library wallet_connect_eth_provider;

import 'package:flutter_web3/flutter_web3.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

class WalletConnectEthereumProvider
    extends Interop<_WalletConnectEthereumProviderImpl> {
  static Future<WalletConnectEthereumProvider> init({
    required String projectId,
    required Map<int, String> rpcMap,
    bool? showQrModal,
    required List<int> chains,
    List<int>? optionalChains,
  }) async {
    chains.forEach((chainId) {
      assert(rpcMap.containsKey(chainId),
          'Chain id ($chainId}) must be in rpc map.');
    });
    var options = _WalletConnectEthereumProviderOptionsImpl(
      projectId: projectId,
      rpcMap: _convertRpc(rpcMap),
      showQrModal: showQrModal,
      chains: chains,
      optionalChains: optionalChains,
    );
    return WalletConnectEthereumProvider.wrap(
      await promiseToFuture(_WalletConnectEthereumProviderImpl.init(options)),
    );
  }

  WalletConnectEthereumProvider.wrap(_WalletConnectEthereumProviderImpl impl)
      : super.internal(impl);

  List<String> get accounts => impl.accounts;

  // String get chainId => impl.chainId;
  int get chainId => impl.chainId;

  bool get connected => impl.connected;

  bool get isConnecting => impl.isConnecting;

  Map<int, String> get rpc => (convertToDart(getProperty(impl, 'rpc')) as Map)
      .map((key, value) => MapEntry(int.parse(key), value.toString()));

  String get rpcUrl => impl.rpcUrl;

  Future<void> connect() =>
      promiseToFuture(callMethod(impl, 'connect', [ConnectOps()]));

  Future<void> disconnect() =>
      promiseToFuture(callMethod(impl, 'disconnect', []));

  int listenerCount([String? eventName]) => impl.listenerCount(eventName);

  List listeners(String eventName) => impl.listeners(eventName);

  off(String eventName, [Function? listener]) => callMethod(impl, 'off',
      listener != null ? [eventName, allowInterop(listener)] : [eventName]);

  on(String eventName, Function listener) =>
      callMethod(impl, 'on', [eventName, allowInterop(listener)]);

  onAccountsChanged(void Function(List<String> accounts) listener) => on(
      'accountsChanged',
      (List<dynamic> accs) => listener(accs.map((e) => e.toString()).toList()));

  once(String eventName, Function listener) =>
      callMethod(impl, 'once', [eventName, allowInterop(listener)]);

  onChainChanged(void Function(int chainId) listener) =>
      on('chainChanged', (dynamic cId) => listener(int.parse(cId.toString())));

  onConnect(void Function() listener) => on('connect', listener);

  onDisconnect(void Function(int code, String reason) listener) =>
      on('disconnect', listener);

  onMessage(void Function(String type, dynamic data) listener) => on(
      'message',
      (ProviderMessage message) =>
          listener(message.type, convertToDart(message.data)));

  removeAllListeners([String? eventName]) => impl.removeAllListeners(eventName);

  Future<T> request<T>(String method, [dynamic params]) async {
    switch (T) {
      case BigInt:
        return BigInt.parse(await request<String>(method, params)) as T;
      default:
        return promiseToFuture<T>(
          callMethod(
            impl,
            'request',
            [
              _RequestArgumentsImpl(
                  method: method, params: params != null ? params : [])
            ],
          ),
        );
    }
  }

  Future<void> walletSwitchChain(int chainId,
      [void Function()? unrecognizedChainHandler]) async {
    try {
      await request('wallet_switchEthereumChain', [
        _EthereumChainParameterImpl(chainId: '0x' + chainId.toRadixString(16)),
      ]);
    } catch (error) {
      switch (convertToDart(error)['code']) {
        case 4902:
          unrecognizedChainHandler != null
              ? unrecognizedChainHandler.call()
              : throw EthereumUnrecognizedChainException(chainId);
          break;
        default:
          rethrow;
      }
    }
  }

  @override
  String toString() => connected
      ? 'WalletConnectEthereumProvider: connected to $rpcUrl ($chainId) with $accounts'
      : 'WalletConnectEthereumProvider: not connected to $rpcUrl($chainId)';
}

dynamic _convertRpc(Map<int, String> rpcMap) => jsify(rpcMap);

@JS()
@anonymous
class _RequestArgumentsImpl {
  external factory _RequestArgumentsImpl({
    required String method,
    dynamic params,
  });

  external String get method;

  external dynamic get params;
}

@JS("WalletConnectEthereumProvider")
class _WalletConnectEthereumProviderImpl {
  external static init(_WalletConnectEthereumProviderOptionsImpl options);

  external List<String> get accounts;

  external int get chainId;

  external bool get connected;

  external bool get isConnecting;

  external String get rpcUrl;

  external int listenerCount([String? eventName]);

  external List<dynamic> listeners(String eventName);

  external removeAllListeners([String? eventName]);
}

@JS()
@anonymous
class _WalletConnectEthereumProviderOptionsImpl {
  external factory _WalletConnectEthereumProviderOptionsImpl({
    String projectId,
    List<int> chains,
    List<int>? optionalChains,
    dynamic rpcMap,
    List<String>? methods,
    bool? showQrModal,
  });

  external String projectId;
  external List<int> chains;
  external List<int>? optionalChains;
  external List<String>? methods;
  external dynamic rpcMap;
  external bool? showQrModal;

// qrModalOptions?: QrModalOptions;
// optionalMethods?: string[];
// events?: string[];
// optionalEvents?: string[];
// metadata?: Metadata;
}

/*
@JS()
@anonymous
class ProviderMessage {
  external dynamic get data;

  external String get type;
}
 */

@JS('console.log')
external void consoleLog(dynamic obj);

@JS()
@anonymous
class ConnectOps {
  external List<int>? chains;
  external List<int>? optionalChains;
  external Map<int, String>? rpcMap;
  external String? pairingTopic;
}

@JS()
@anonymous
class _EthereumChainParameterImpl {
  external factory _EthereumChainParameterImpl({
    required String chainId,
  });

  external String get chainId;
}
