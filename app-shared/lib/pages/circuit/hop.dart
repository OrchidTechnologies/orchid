import 'package:flutter/material.dart';

class Circuit {
  List<Hop> hops;

  Circuit(this.hops);

  Circuit.fromJson(Map<String, dynamic> json) {
    this.hops = (json['hops'] as List<dynamic>).map((el) {
      return Hop.fromJson(el);
    }).toList();
  }

  Map<String, dynamic> toJson() => {'hops': hops};
}

class Hop {
  final String protocol;
  final String secret; // hex
  final String funder; // 0x prefixed hex

  Hop({this.protocol = "orchid", this.secret, this.funder}) {
    //assert(funder.toLowerCase().startsWith("0x"));
  }

  Hop.fromJson(Map<String, dynamic> json)
      : protocol = json['protocol'],
        secret = json['secret'],
        funder = json['funder'];

  Map<String, dynamic> toJson() =>
      {'protocol': protocol, 'secret': secret, 'funder': funder};
}

/// A Hop with a locally unique identifier used for display purposes.
/// Note: If we can guarantee uniqueness of a hash later we can drop this.
class UniqueHop {
  final int key;
  final Hop hop;

  UniqueHop({@required this.key, @required this.hop});

  bool operator ==(o) => o is UniqueHop && o.key == key;
}
