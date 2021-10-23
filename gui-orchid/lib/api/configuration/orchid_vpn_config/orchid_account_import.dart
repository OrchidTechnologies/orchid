import 'dart:async';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/hex.dart';
import '../../../util/js_config.dart';

/// Import orchid accounts
class OrchidAccountImport {
  /// Parse a V1 account identity config from JavaScript (not JSON), e.g.
  /// account = {secret:"0xfb5d5..."}
  static ParseOrchidIdentityResult parseOrchidIdentity(
      String js, List<StoredEthereumKey> existingKeys) {
    try {
      var config = JSConfig(js);
      var secret = config.evalString('account.secret');
      var newKeys = <StoredEthereumKey>[]; // type required here
      var signer = resolveImportedKey(secret, existingKeys, newKeys);
      return ParseOrchidIdentityResult(signer, newKeys.isNotEmpty);
    } catch (err) {
      print("Error parsing orchid identity: $err");
      throw err;
    }
  }

  /// Parse a 64 character raw hex encoded key with leading zeroes if required.
  /// The string may optionally be prefixed with "0x" making it 66 characters.
  /// The string is trimmed and case is ignored.
  static ParseOrchidIdentityResult parseRawKey(
      String secretIn, List<StoredEthereumKey> existingKeys) {
    var secret = secretIn.toLowerCase().trim();
    RegExp hexEncodedSecret = RegExp(r'^(0x)?[a-f0-9]{64}$');
    if (!hexEncodedSecret.hasMatch(secret)) {
      throw Exception("Invalid key");
    }
    try {
      var newKeys = <StoredEthereumKey>[];
      var signer = resolveImportedKey(
          secret, existingKeys, newKeys);
      return ParseOrchidIdentityResult(signer, newKeys.isNotEmpty);
    } catch (err) {
      print("Error parsing orchid identity: $err");
      throw err;
    }
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
      //log("import: found existing key");
    } catch (err) {
      // Generate a new temporary key
      key = StoredEthereumKey(
          imported: true,
          time: DateTime.now(),
          uid: Crypto.uuid(),
          private: BigInt.parse(secret, radix: 16));
      newKeys.add(key);
      //log("import: preparing new key");
    }
    return key;
  }

  static String removeNewlines(String text) {
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

/// This class imports a V0 or V1 style account identity or raw key.
class ParseOrchidIdentityResult {
  final StoredEthereumKey signer;
  final bool isNew;

  ParseOrchidIdentityResult(this.signer, this.isNew);

  static Future<ParseOrchidIdentityResult> parse(
      String config, {
        List<StoredEthereumKey> keys,
      }) async {
    var existingKeys = keys ?? await UserPreferences().keys.get();

    // Try to parse as a V1 identity (which may be a subset of a V0 account)
    try {
      return OrchidAccountImport.parseOrchidIdentity(config, existingKeys);
    } catch (err) {
      // fall through to raw key test
    }

    // Try to parse as a raw hex key
    return OrchidAccountImport.parseRawKey(config, existingKeys);
  }

  @override
  String toString() {
    return 'ParseOrchidIdentityResult{signer: $signer, isNew: $isNew}';
  }
}

