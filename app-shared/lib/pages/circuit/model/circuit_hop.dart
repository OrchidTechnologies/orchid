import 'package:flutter/foundation.dart';

enum HopProtocol { Orchid, OpenVPN }

// A hop element of a circuit
class CircuitHop {
  HopProtocol protocol;

  CircuitHop(this.protocol);

  CircuitHop.fromJson(Map<String, dynamic> json)
      : this.protocol = stringToProtocol(json['protocol']);

  Map<String, dynamic> toJson() => {'protocol': protocolToString(protocol)};

  String displayName() {
    switch (protocol) {
      case HopProtocol.Orchid:
        return "Orchid";
        break;
      case HopProtocol.OpenVPN:
        return "OpenVPN";
        break;
      default:
        return "";
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
}
