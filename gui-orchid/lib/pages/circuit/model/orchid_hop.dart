import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_crypto.dart';

import 'circuit_hop.dart';

class OrchidHop extends CircuitHop {
  // The app default, which may be overridden by the user specified settings
  // default or on a per-hop basis.
  static const String appDefaultCurator = "partners.orch1d.eth";

  final String curator; // URI
  final EthereumAddress funder;
  final StoredEthereumKeyRef keyRef;

  OrchidHop(
      {@required this.curator, @required this.funder, @required this.keyRef})
      : super(HopProtocol.Orchid);

  // Construct an Orchid Hop using an existing hop's properties as defaults.
  // The hop may be null, in which case this serves as a loose constructor.
  OrchidHop.from(OrchidHop hop,
      {String curator, EthereumAddress funder, StoredEthereumKeyRef keyRef})
      : this(
            curator: curator ?? hop?.curator,
            funder: funder ?? hop?.funder,
            keyRef: keyRef ?? hop?.keyRef);

  factory OrchidHop.fromJson(Map<String, dynamic> json) {
    var curator = json['curator'] ?? appDefaultCurator;
    var funder = EthereumAddress.from(json['funder']);
    var keyRef = StoredEthereumKeyRef.from(json['keyRef']);
    return OrchidHop(curator: curator, funder: funder, keyRef: keyRef);
  }

  Map<String, dynamic> toJson() => {
        'curator': curator,
        'protocol': CircuitHop.protocolToString(protocol),

        // Always render funder with the hex prefix as required by the config.
        'funder': funder.toString(prefix: true),

        'keyRef': keyRef.toString(),
      };

  Future<String> accountConfigString() async {
    var funder = this.funder.toString();
    var secret = (await this.keyRef.get()).private.toRadixString(16);
    return 'account={ protocol: "orchid", funder: "$funder", secret: "$secret" }';
  }
}
