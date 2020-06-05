import 'circuit_hop.dart';

class WireGuardHop extends CircuitHop {
  final String config;

  WireGuardHop({this.config}) : super(HopProtocol.WireGuard);

  factory WireGuardHop.fromJson(Map<String, dynamic> json) {
    return WireGuardHop(
      config: json['config'],
    );
  }

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'config': config,
      };
}
