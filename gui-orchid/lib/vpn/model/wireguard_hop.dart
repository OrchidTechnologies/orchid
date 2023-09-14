
import 'package:orchid/vpn/model/circuit_hop.dart';

class WireGuardHop extends CircuitHop {
  final String? config;

  WireGuardHop({this.config}) : super(HopProtocol.WireGuard);

  WireGuardHop.fromJson(Map<String, dynamic> json)
      : this.config = json['config'],
        super(HopProtocol.WireGuard);

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'config': config,
      };
}
