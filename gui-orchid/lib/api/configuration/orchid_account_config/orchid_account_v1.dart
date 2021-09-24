import 'dart:async';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import '../../../util/js_config.dart';
import 'orchid_account_v0.dart';

/// Support for reading and generating the JavaScript configuration file used by the Orchid VPN.
class OrchidAccountConfigV1 {
  /// Parse a V1 account identity config.
  // e.g. 'account = {secret:"0xfb5d5..."}'
  static ParseOrchidIdentityResult parseOrchidIdentity(
      String js, List<StoredEthereumKey> existingKeys) {
    try {
      var config = JSConfig(js);
      var secret = config.evalString('account.secret');
      var newKeys = <StoredEthereumKey>[]; // type required here
      var signer = OrchidAccountConfigV0.resolveImportedKey(
          secret, existingKeys, newKeys);
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
      var signer = OrchidAccountConfigV0.resolveImportedKey(
          secret, existingKeys, newKeys);
      return ParseOrchidIdentityResult(signer, newKeys.isNotEmpty);
    } catch (err) {
      print("Error parsing orchid identity: $err");
      throw err;
    }
  }
}

class ParseOrchidIdentityResult {
  final StoredEthereumKey signer;
  final bool isNew;

  ParseOrchidIdentityResult(this.signer, this.isNew);

  @override
  String toString() {
    return 'ParseOrchidIdentityResult{signer: $signer, isNew: $isNew}';
  }
}

/// This class supports migration to the V1 gui by encapsulating either
/// an imported V0 account or V1 identity.
class ParseOrchidAccountResult {
  final ParseOrchidIdentityResult identityV1;
  final ParseOrchidAccountResultV0 accountV0;

  ParseOrchidAccountResult({this.identityV1, this.accountV0});

  static Future<ParseOrchidAccountResult> parse(
    String config, {
    List<StoredEthereumKey> keys,
    bool v0Only = false, // If true only V0 account strings will be valid
  }) async {
    var existingKeys = keys ?? await UserPreferences().getKeys();

    // Try to parse as a V0 account
    try {
      return ParseOrchidAccountResult(
          accountV0:
              OrchidAccountConfigV0.parseOrchidAccount(config, existingKeys));
    } catch (err) {
      if (v0Only) {
        throw err;
      }
    }

    // Try to parse as a V1 identity (which may be a subset of a V0 account)
    try {
      return ParseOrchidAccountResult(
          identityV1:
              OrchidAccountConfigV1.parseOrchidIdentity(config, existingKeys));
    } catch (err) {
      // fall through to raw key test
    }

    // Try to parse as a raw hex key
    return ParseOrchidAccountResult(
        identityV1: OrchidAccountConfigV1.parseRawKey(config, existingKeys));
  }

  @override
  String toString() {
    return 'ParseOrchidAccountResult{identity: $identityV1, account: $accountV0}';
  }
}
