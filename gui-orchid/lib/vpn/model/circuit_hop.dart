import 'package:flutter/material.dart';
import 'package:orchid/util/collections.dart';
import 'package:orchid/util/localization.dart';

enum HopProtocol {
  // The protocol 'Orchid' represents all versions here (orchid and orch1d).
  Orchid,
  OpenVPN,
  WireGuard,
}

// A hop element of a circuit
class CircuitHop {
  HopProtocol protocol;

  CircuitHop(this.protocol);

  CircuitHop.fromJson(Map<String, dynamic> json)
      : this.protocol = stringToProtocol(json['protocol']);

  Map<String, dynamic> toJson() => {'protocol': protocolToString(protocol)};

  String displayName(BuildContext context) {
    switch (protocol) {
      case HopProtocol.Orchid:
        return context.s.orchid;
      case HopProtocol.OpenVPN:
        return context.s.openVPN;
      case HopProtocol.WireGuard:
        return context.s.wireguard;
      default:
        throw Exception();
    }
  }

  // Return the protocol matching the string name ignoring case
  static HopProtocol stringToProtocol(String s) {
    // Accept orchid or orch1d as a protocol name (this could be cleaner).
    if (s == 'orch1d') {
      s = 'orchid';
    }
    return HopProtocol.values.firstWhere(
      (e) => e.toString().toLowerCase() == ("$HopProtocol." + s).toLowerCase(),
    ); // ug
  }

  static protocolToString(HopProtocol type) {
    return type.toString().substring("$HopProtocol.".length);
  }
}

// TODO: As part of the first data migration we will add a uuid allowing us
// TODO: to get rid of this.
/// A Hop with a locally unique identifier used for display purposes.
/// Note: If we can guarantee uniqueness of a hash later we can drop this.
class UniqueHop {
  final int? key;
  final CircuitHop hop;

  UniqueHop({required this.key, required this.hop});

  // Create a UniqueHop preserving any key from a previous UniqueHop.
  UniqueHop.from(UniqueHop? uniqueHop, {required CircuitHop hop})
      : this(key: uniqueHop?.key, hop: hop);

  // Wrap the hops with a locally unique id for the UI
  static List<UniqueHop> wrap(List<CircuitHop> hops, int keyBase) {
    return mapIndexed(hops, ((index, hop) {
      var key = keyBase + index;
      return UniqueHop(key: key, hop: hop);
    })).toList();
  }

  /// Hash of the hop content.
  int get contentHash => hop.toJson().toString().hashCode;
}
