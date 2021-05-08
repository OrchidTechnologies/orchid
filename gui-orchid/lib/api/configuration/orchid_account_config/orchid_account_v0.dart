import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/util/hex.dart';

/// Support for reading and generating Orchid account json v0.
class OrchidAccountConfigV0 {

  /// Parse an imported Orchid account from JS (input text containing a valid account assignment).
  /// TODO: We should update this to use our JSConfig (real) JS parser.
  static ParseOrchidAccountResultV0 parseOrchidAccount(
      String js, List<StoredEthereumKey> existingKeys) {
    // Remove newlines, etc.
    js = normalizeInputJSON(js);

    // Match an 'account' variable assignment to a JS object literal:
    // 'account = protocol:"orchid",funder:"0x2Be...",secret:"0xfb5d5..."'
    RegExp exp =
        RegExp(r'\s*[Aa][Cc][Cc][Oo][Uu][Nn][Tt]\s*=\s*(\{.*\})\s*;?\s*');
    var match = exp.firstMatch(js);
    var accountString = match.group(1);

    // Quote keys JSON style:
    // 'protocol:"orchid", funder:"0x2Be...", => '"protocol":"orchid", "funder":"0x2Be...",
    accountString = quoteKeysJsonStyle(accountString);

    // Convert to JSON
    Map<String, dynamic> json = jsonDecode(accountString);

    if (json['protocol'].toLowerCase() != 'orchid') {
      throw Exception("Not an orchid account");
    }

    EthereumAddress funder = EthereumAddress.from(json['funder']);
    String secret = json['secret'];
    String curator = json['curator'];

    // Resolve imported secrets to existing stored keys or new temporary keys
    var newKeys = <StoredEthereumKey>[]; // type required here
    StoredEthereumKey key = resolveImportedKey(secret, existingKeys, newKeys);
    var orchidAccount =
        OrchidAccountV0(curator: curator, funder: funder, signer: key);
    return ParseOrchidAccountResultV0(account: orchidAccount, newKeys: newKeys);
  }

  /// Find an imported key secret in existing keys or create a new key and
  /// add it to the newKeys list.  In both cases the key is returned.
  static StoredEthereumKey resolveImportedKey(String secret,
      List<StoredEthereumKey> existingKeys, List<StoredEthereumKey> newKeys) {
    if (secret == null) {
      throw Exception("missing secret");
    }
    secret = Hex.remove0x(secret);
    StoredEthereumKey key;
    try {
      // Find an existing key match
      var secretInt = BigInt.parse(secret, radix: 16);
      key = existingKeys.firstWhere((key) {
        return key.private == secretInt;
      });
      //print("parse: found existing key");
    } catch (err) {
      // Generate a new temporary key
      key = StoredEthereumKey(
          imported: true,
          time: DateTime.now(),
          uid: Crypto.uuid(),
          private: BigInt.parse(secret, radix: 16));
      newKeys.add(key);
      //print("parse: generated new key");
    }
    return key;
  }

  // TODO: Move to JSON lib
  static String normalizeInputJSON(String text) {
    text = text.replaceAll("\n", " ");
    text = text.replaceAll("\r", " ");
    return text;
  }

  // Quote the keys in name-value key pairs, JSON style:
  //  [curator: "partners.orch1d.eth",...  => ["curator": "partners.orch1d.eth",...
  static String quoteKeysJsonStyle(String text) {
    return text.replaceAllMapped(
        RegExp(r'([A-Za-z0-9_-]{1,})\s*:'), (Match m) => '"${m[1]}":');
  }
}

// An Orchid account
class OrchidAccountV0 {
  final String curator;
  final EthereumAddress funder;
  final StoredEthereumKey signer;

  OrchidAccountV0(
      {@required this.curator, @required this.funder, @required this.signer});
}

/// Result holding a parsed imported Orchid account. The account signer key refers
/// to either an existing key in the user's keystore or a newly imported but not yet
/// saved temporary key in the newKeys list.
class ParseOrchidAccountResultV0 {
  final OrchidAccountV0 account;
  final List<StoredEthereumKey> newKeys;

  ParseOrchidAccountResultV0({this.account, this.newKeys});

  @override
  String toString() {
    return 'ParseOrchidAccountResultV0{account: $account, newKeys: $newKeys}';
  }
}
