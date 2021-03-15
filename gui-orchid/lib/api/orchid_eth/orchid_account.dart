import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';

import '../orchid_log_api.dart';

/// The base model for accounts including signer, chain, and funder.
class Account {
  final String identityUid; // stored signer key uid
  final int version; // The contract version: 0 for the original OXT contract.
  final int chainId; // @nullable
  final EthereumAddress funder; // @nullable

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  Account({
    @required this.identityUid,
    this.version = 0,
    this.chainId,
    this.funder,
  });

  /// Indicates that this account selects an identity but not yet a designated
  /// account for the identity.
  bool get isIdentityPlaceholder {
    return chainId == null && funder == null;
  }

  Account.fromJson(Map<String, dynamic> json)
      : this.identityUid = json['identityUid'],
        this.version = int.parse(json['version']),
        this.chainId = parseNullableInt(json['chainId']),
        this.funder = EthereumAddress.fromNullable(json['funder']);

  static int parseNullableInt(String val) {
    return val == null ? null : int.parse(val);
  }

  Map<String, dynamic> toJson() => {
        'version': version.toString(),
        'identityUid': identityUid,
        'chainId': chainId == null ? null : chainId.toString(),
        'funder': funder == null ? null : funder.toString()
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          identityUid == other.identityUid &&
          version == other.version &&
          chainId == other.chainId &&
          funder == other.funder;

  @override
  int get hashCode =>
      identityUid.hashCode ^
      version.hashCode ^
      chainId.hashCode ^
      funder.hashCode;

  @override
  String toString() {
    return 'Account{identityUid: $identityUid, chainId: $chainId, funder: $funder}';
  }
}
