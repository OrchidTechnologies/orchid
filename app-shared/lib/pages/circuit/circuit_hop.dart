import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';

enum Protocol { Orchid, OpenVPN }

class Circuit {
  List<CircuitHop> hops = [];

  Circuit(this.hops);

  // Handle the heterogeneous list of hops
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
  final String funder; // 0x prefixed hex
  final StoredEthereumKeyRef keyRef;

  OrchidHop({this.funder, this.keyRef}) : super(Protocol.Orchid);

  factory OrchidHop.fromJson(Map<String, dynamic> json) {
    return OrchidHop(
        funder: json['funder'], keyRef: StoredEthereumKeyRef(json['keyRef']));
  }

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'funder': funder,
        'keyRef': keyRef.toString(),
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
}

class EditableHop extends ValueNotifier<UniqueHop> {
  EditableHop(UniqueHop value) : super(value);
  EditableHop.empty() : super(null);
}

abstract class HopEditor<T extends CircuitHop> {
  final EditableHop editableHop;
  HopEditor(this.editableHop);
}

// Debating whether making these fully typed is helpful.
/*
switch (hop.protocol) {
  case Protocol.Orchid:
    return UniqueHop<OrchidHop>(key: key, hop: hop);
  case Protocol.OpenVPN:
    return UniqueHop<OpenVPNHop>(key: key, hop: hop);
  default:
    throw Exception();
}
...

class UniqueHop<T extends CircuitHop> {
  final int key;
  final T hop;

  UniqueHop({@required this.key, @required this.hop});
}

class EditableHop<T extends CircuitHop> extends ValueNotifier<UniqueHop<T>> {
  EditableHop(UniqueHop<T> value) : super(value);
  EditableHop.empty() : super(null);
}

abstract class HopEditor<T extends CircuitHop> {
  final EditableHop<T> editableHop;
  HopEditor(this.editableHop);
}

*/

