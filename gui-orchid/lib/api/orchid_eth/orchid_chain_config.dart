import 'package:orchid/util/collections.dart';

/// User overrides for default chain configuration
class ChainConfig {
  final int chainId;
  final bool enabled;
  final String? rpcUrl;

  /// return true if this config is equivalent to no config for the chain
  bool get isEmpty {
    return enabled && rpcUrl == null;
  }

  ChainConfig({
    required this.chainId,
    required this.enabled,
    this.rpcUrl,
  });

  ChainConfig.fromJson(Map<String, dynamic> json)
      : this.chainId = int.parse(json['chainId']),
        this.enabled = json['enabled'].toString().toLowerCase() == 'true',
        this.rpcUrl = json['rpcUrl'];

  Map<String, dynamic> toJson() => {
        'chainId': chainId.toString(),
        'enabled': enabled.toString(),
        'rpcUrl': rpcUrl,
      };

  static Map<int, ChainConfig> map(Iterable<ChainConfig> iterable) {
    return iterable.toMap(withKey: (e) => e.chainId, withValue: (e) => e);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChainConfig &&
          runtimeType == other.runtimeType &&
          chainId == other.chainId &&
          enabled == other.enabled &&
          rpcUrl == other.rpcUrl;

  @override
  int get hashCode => chainId.hashCode ^ enabled.hashCode ^ rpcUrl.hashCode;
}
