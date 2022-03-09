import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/pages/circuit/model/wireguard_hop.dart';

import 'circuit_hop.dart';
import 'openvpn_hop.dart';
import 'orchid_hop.dart';

class Circuit {
  List<CircuitHop> hops = [];

  Circuit(this.hops);

  Set<Account> get activeOrchidAccounts => (hops ?? [])
      .whereType<OrchidHop>()
      .map((hop) => hop.account)
      .toSet();

  // Handle the heterogeneous list of hops
  Circuit.fromJson(Map<String, dynamic> json) {
    this.hops = (json['hops'] as List<dynamic>)
        // ignore: missing_return
        .map((el) {
          CircuitHop hop = CircuitHop.fromJson(el);
          switch (hop.protocol) {
            case HopProtocol.Orchid:
              return OrchidHop.fromJson(el);
            case HopProtocol.OpenVPN:
              return OpenVPNHop.fromJson(el);
            case HopProtocol.WireGuard:
              return WireGuardHop.fromJson(el);
          }
        })
        .where((val) => val != null) // ignore unrecognized hop types
        .toList();
  }

  Map<String, dynamic> toJson() => {'hops': hops};

  @override
  String toString() {
    return 'Circuit{hops: $hops}';
  }
}

class Hops {
  List<CircuitHop> hops = [];

  Hops(this.hops);

  // Handle the heterogeneous list of hops
  Hops.fromJson(Map<String, dynamic> json) {
    var circuit = Circuit.fromJson(json);
    this.hops = circuit.hops;
  }

  Map<String, dynamic> toJson() => {'hops': hops};

}
