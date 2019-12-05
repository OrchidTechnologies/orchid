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
      : super(Protocol.Orchid);

  // Construct an Orchid Hop using an existing hop's properties as defaults.
  // The hop may be null, in which case this serves as a loose constructor.
  OrchidHop.from(OrchidHop hop,
      {String curator, EthereumAddress funder, StoredEthereumKeyRef keyRef})
      : this(
            curator: curator ?? hop?.curator,
            funder: funder ?? hop?.funder,
            keyRef: keyRef ?? hop?.keyRef);

  factory OrchidHop.fromJson(Map<String, dynamic> json) {
    var curator = json['curator'];
    var funder = EthereumAddress.from(json['funder']);
    var keyRef = StoredEthereumKeyRef(json['keyRef']);
    return OrchidHop(curator: curator, funder: funder, keyRef: keyRef);
  }

  Map<String, dynamic> toJson() => {
        'curator': curator,
        'protocol': CircuitHop.protocolToString(protocol),

        // Always render funder with the hex prefix as required by the config.
        'funder': funder.toString(prefix: true),

        'keyRef': keyRef.toString(),
      };
}
