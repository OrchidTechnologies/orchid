// @dart=2.9
import 'circuit_hop.dart';

class WireGuardHop extends CircuitHop {
  final String config;

  WireGuardHop({this.config}) : super(HopProtocol.WireGuard);

  WireGuardHop.fromJson(Map<String, dynamic> json)
      : this.config = json['config'],
        super(HopProtocol.WireGuard);

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'config': config,
      };
}
