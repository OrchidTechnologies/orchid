import 'package:flutter/material.dart';

enum Protocol { Orchid, OpenVPN }

class Circuit {
  List<CircuitHop> hops = [];

  Circuit(this.hops);

  Circuit.fromJson(Map<String, dynamic> json) {
    this.hops = (json['hops'] as List<dynamic>)
        .map((el) {
          CircuitHop hop = CircuitHop.fromJson(el);
          switch (hop.protocol) {
            case Protocol.Orchid:
              return OrchidHop.fromJson(el);
            case Protocol.OpenVPN:
              return OpenVPNHop.fromJson(el);
            default:
              return null;
          }
        })
        .where((val) => val != null) // ignore unrecognized hop types
        .toList();
  }

  Map<String, dynamic> toJson() => {'hops': hops};
}

// A hop element of a circuit
class CircuitHop {
  Protocol protocol;

  CircuitHop(this.protocol);

  CircuitHop.fromJson(Map<String, dynamic> json)
      : this.protocol = stringToProtocol(json['protocol']);

  Map<String, dynamic> toJson() => {'protocol': protocolToString(protocol)};

  String displayName() {
    switch (protocol) {
      case Protocol.Orchid:
        return "Orchid";
        break;
      case Protocol.OpenVPN:
        return "Open VPN";
        break;
      default:
        return "";
    }
  }

  static stringToProtocol(String s) {
    return Protocol.values.firstWhere((e) => e.toString() == "Protocol." + s,
        orElse: () {
          return null;
        }); // ug
  }

  static protocolToString(Protocol type) {
    return type.toString().substring("Protocol.".length);
  }

}

class OrchidHop extends CircuitHop {
  final String secret; // hex
  final String funder; // 0x prefixed hex

  OrchidHop({this.secret, this.funder}) : super(Protocol.Orchid);

  factory OrchidHop.fromJson(Map<String, dynamic> json) {
    return OrchidHop(secret: json['secret'], funder: json['funder']);
  }

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'secret': secret,
        'funder': funder
      };
}

class OpenVPNHop extends CircuitHop {
  final String userName;
  final String userPassword;
  final String ovpnConfig;

  OpenVPNHop({this.userName, this.userPassword, this.ovpnConfig})
      : super(Protocol.OpenVPN);

  factory OpenVPNHop.fromJson(Map<String, dynamic> json) {
    return OpenVPNHop(
        userName: json['username'],
        userPassword: json['password'],
        ovpnConfig: json['ovpnfile']);
  }

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'username': userName,
        'password': userPassword,
        'ovpnfile': ovpnConfig
      };
}

/// A Hop with a locally unique identifier used for display purposes.
/// Note: If we can guarantee uniqueness of a hash later we can drop this.
class UniqueHop {
  final int key;
  final CircuitHop hop;

  UniqueHop({@required this.key, @required this.hop});

  bool operator ==(o) => o is UniqueHop && o.key == key;
}
