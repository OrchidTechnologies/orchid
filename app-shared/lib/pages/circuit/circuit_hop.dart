import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/pages/common/app_buttons.dart';

import 'add_hop_page.dart';

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
  // The app default, which may be overridden by the user specified settings
  // default or on a per-hop basis.
  static const String appDefaultCurator = "partners.orch1d.eth";
  
  final String curator;
  final String funder;
  final StoredEthereumKeyRef keyRef;

  OrchidHop(
      {@required this.curator, @required this.funder, @required this.keyRef})
      : super(Protocol.Orchid);

  // Construct an Orchid Hop using an existing hop as defaults.
  OrchidHop.from(OrchidHop hop,
      {String curator, String funder, StoredEthereumKeyRef keyRef})
      : this(
            curator: curator ?? hop?.curator,
            funder: funder ?? hop?.funder,
            keyRef: keyRef ?? hop?.keyRef);

  factory OrchidHop.fromJson(Map<String, dynamic> json) {
    var curator = json['curator'];
    var keyRefValue = json['keyRef'];

    // Key references are explicitly allowed to be null.
    var nullableKeyRef =
        keyRefValue != null ? StoredEthereumKeyRef(keyRefValue) : null;
    return OrchidHop(
        curator: curator, funder: json['funder'], keyRef: nullableKeyRef);
  }

  Map<String, dynamic> toJson() => {
        'curator': curator,
        'protocol': CircuitHop.protocolToString(protocol),
        'funder': funder,
        'keyRef': keyRef?.toString(), // Key references are nullable
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

  // Create a UniqueHop preserving any key from a previous UniqueHop.
  UniqueHop.from(UniqueHop uniqueHop, {CircuitHop hop, int index = 0})
      : this(
            key:
                uniqueHop?.key ?? DateTime.now().millisecondsSinceEpoch + index,
            hop: hop);
}

class EditableHop extends ValueNotifier<UniqueHop> {
  EditableHop(UniqueHop value) : super(value);

  EditableHop.empty() : super(null);

  void update(CircuitHop hop) {
    value = UniqueHop.from(value, hop: hop);
  }
}

enum HopEditorMode { Create, Edit, View }

class HopEditor<T extends CircuitHop> extends StatefulWidget {
  final EditableHop editableHop;
  final AddFlowCompletion onAddFlowComplete;

  // In create mode the editor offers a "save" button that pops the view and
  // returns the value on the context.  If the user navigates back without
  // saving the context result will be null.
  final HopEditorMode mode;

  HopEditor(
      {@required this.editableHop,
      @required this.mode,
      this.onAddFlowComplete});

  Widget buildSaveButton(BuildContext context, {bool isValid = true}) {
    return SaveActionButton(
        isValid: isValid,
        onPressed: () {
          this.onAddFlowComplete(this.editableHop.value.hop);
        });
  }

  bool editable() {
    return mode != HopEditorMode.View;
  }

  bool readOnly() {
    return !editable();
  }

  @override
  Widget build(BuildContext context) {
    throw Exception("implement in subclass");
  }

  @override
  State<StatefulWidget> createState() {
    throw Exception("implement in subclass");
  }
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
