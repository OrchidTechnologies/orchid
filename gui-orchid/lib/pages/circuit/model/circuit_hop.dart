import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/util/collections.dart';

enum HopProtocol { Orchid, OpenVPN, WireGuard }

// A hop element of a circuit
class CircuitHop {
  String uuid;
  HopProtocol protocol;

  CircuitHop(this.protocol) {
  }

  CircuitHop.fromJson(Map<String, dynamic> json)
      : this.protocol = stringToProtocol(json['protocol']);

  Map<String, dynamic> toJson() => {'protocol': protocolToString(protocol)};

  String displayName(BuildContext context) {
    switch (protocol) {
      case HopProtocol.Orchid:
        return S.of(context).orchid;
        break;
      case HopProtocol.OpenVPN:
        return S.of(context).openVPN;
        break;
      case HopProtocol.WireGuard:
        return S.of(context).wireguard;
        break;
    }
  }

  // Return the protocol matching the string name ignoring case
  static stringToProtocol(String s) {
    return HopProtocol.values.firstWhere(
        (e) =>
            e.toString().toLowerCase() == ("$HopProtocol." + s).toLowerCase(),
        orElse: () {
      return null;
    }); // ug
  }

  static protocolToString(HopProtocol type) {
    return type.toString().substring("$HopProtocol.".length);
  }
}

/// A Hop with a locally unique identifier used for display purposes.
/// Note: If we can guarantee uniqueness of a hash later we can drop this.
class UniqueHop {
  final int key;
  final CircuitHop hop;

  UniqueHop({@required this.key, @required this.hop});

  // Create a UniqueHop preserving any key from a previous UniqueHop.
  UniqueHop.from(UniqueHop uniqueHop, {CircuitHop hop})
      : this(key: uniqueHop?.key, hop: hop);

  // Wrap the hops with a locally unique id for the UI
  static List<UniqueHop> wrap(List<CircuitHop> hops, int keyBase) {
    return mapIndexed(hops ?? [], ((index, hop) {
      var key = keyBase + index;
      return UniqueHop(key: key, hop: hop);
    })).toList();
  }

  /// Hash of the hop content.
  int get contentHash => hop.toJson().toString().hashCode;
}

