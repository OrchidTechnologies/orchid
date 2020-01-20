import 'dart:async';
import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/util/hex.dart';

import 'orchid_api.dart';

// TODO: Refactor this file and add unit tests.
/// Support for generating the JavaScript configuration file used by the Orchid VPN.
class OrchidVPNConfig {
  /// Generate the hops list portion of the VPN config managed by the GUI.
  /// The desired format is a JavaScript object literal assignment, e.g.:
  /// hops = [{protocol: "orchid", secret: "HEX", funder: "0xHEX"}, {protocol: "orchid", secret: "HEX", funder: "0xHEX"}];
  static Future<String> generateHopsConfig() async {
    Circuit circuit = await UserPreferences().getCircuit();
    List<StoredEthereumKey> keys = await UserPreferences().getKeys();
    List<CircuitHop> hops = circuit?.hops ?? [];

    /// Convert each hop to a json map and replace values as required by the rendered config.
    var hopsListConfig = hops.map((hop) {
      // Resolve key references
      var resolvedHop = resolveKeyReferencesForExport(hop.toJson(), keys);
      return resolvedHop.map((String key, dynamic value) {
        // The protocol value is transformed to lowercase.
        if (key == "protocol") {
          value = value.toString().toLowerCase();
        }
        // Quote all values for now
        return MapEntry(key, "\"$value\"");
      }).toString();
    }).toList();

    return "hops = $hopsListConfig;";
  }

  /// Replace JSON "keyRef" key references with private key "secret" values.
  static Map<String, dynamic> resolveKeyReferencesForExport(
      Map<String, dynamic> json, List<StoredEthereumKey> keys) {
    return json.map((String key, dynamic value) {
      // Key references are replaced with the actual key values.
      if (key == "keyRef") {
        String secret;
        if (value != null) {
          var keyRef = StoredEthereumKeyRef.from(value);
          try {
            StoredEthereumKey key = keyRef.getFrom(keys);
            secret = "${key.private.toRadixString(16)}";
          } catch (err) {
            //print("existing key refs: ");
            //for (var key in keys) {
              //print("keyref = ${key.uid}");
            //}
            throw Exception("resolveKeyReferences invalid key ref: $keyRef");
          }
        } else {
          secret = null;
        }
        return MapEntry("secret", secret);
      }
      return MapEntry(key, value);
    });
  }

  /// Parse JavaScript text containing a variable assignment expression for the `hops`
  /// configuration list and return the Circuit.  e.g.
  ///   hops = [{curator: "partners.orch1d.eth", protocol: "orchid", funder: "0x405bc10e04e3f487e9925ad5815e4406d78b769e", secret: "894643a2de07568a51f7fe59650365dea0e04376819ecff08e686face92ca16e"}];
  /// Note: For now we are transforming the JS object literal into JSON.
  /// Note: When this grows more complex we will switch to the samurai JS parser:
  /// Note: https://github.com/samurai-dart/samurai
  static ParseCircuitResult parseCircuit(
      String js, List<StoredEthereumKey> existingKeys) {

    // Remove newlines, etc.
    js = _normalizeInputJSON(js);

    // Match a 'hops' variable assignment to a list of JS object literals:
    // hops = [{curator: "partners.orch1d.eth",...
    RegExp exp = RegExp(r'\s*[Hh][Oo][Pp][Ss]\s*=\s*(\[.*\])\s*;?\s*');
    var match = exp.firstMatch(js);
    var hopsString = match.group(1);

    // Quote keys JSON style:
    //  [{curator: "partners.orch1d.eth",...  => [{"curator": "partners.orch1d.eth",...
    hopsString = _quoteKeysJsonStyle(hopsString);

    // Wrap the top level JSON with a 'hops' key:
    // {"hops": [...]}
    hopsString = '{"hops": $hopsString}';

    // Convert to JSON
    Map<String, dynamic> json = jsonDecode(hopsString);

    // Resolve imported secrets to existing stored keys or new temporary keys
    var tempKeys = List<StoredEthereumKey>();
    var uid = DateTime.now().millisecondsSinceEpoch;
    List<dynamic> hops = json['hops'];
    hops.asMap().forEach((index, hop) {
      // Only interested in Orchid hops here
      if (hop['protocol'] != "orchid") {
        return;
      }
      _resolveImportedKeyFromJSON(hop, existingKeys, (uid + index), tempKeys);
    });

    return ParseCircuitResult(
        circuit: Circuit.fromJson(json), newKeys: tempKeys);
  }

  /// Parse an imported Orchid account from JS (input text containing a valid account assignment).
  static ParseOrchidAccountResult parseOrchidAccount(
      String js, List<StoredEthereumKey> existingKeys) {
    // Remove newlines, etc.
    js = _normalizeInputJSON(js);

    // Match an 'account' variable assignment to a JS object literal:
    // 'account = {protocol:"orchid",funder:"0x2Be...",secret:"0xfb5d5..."}'
    RegExp exp = RegExp(r'\s*[Aa][Cc][Cc][Oo][Uu][Nn][Tt]\s*=\s*(\{.*\})\s*;?\s*');
    var match = exp.firstMatch(js);
    var accountString = match.group(1);

    // Quote keys JSON style:
    // '{protocol:"orchid", funder:"0x2Be...", => '{"protocol":"orchid", "funder":"0x2Be...",
    accountString = _quoteKeysJsonStyle(accountString);

    // Convert to JSON
    Map<String, dynamic> json = jsonDecode(accountString);

    if (json['protocol'].toLowerCase() != 'orchid') {
      throw Exception("Not an orchid account");
    }

    EthereumAddress funder = EthereumAddress.from(json['funder']);
    String secret = json['secret'];

    // Resolve imported secrets to existing stored keys or new temporary keys
    var newKeys = List<StoredEthereumKey>();
    var uid = DateTime.now().millisecondsSinceEpoch;
    StoredEthereumKey key = _resolveImportedKey(secret, existingKeys, uid, newKeys);
    var orchidAccount = OrchidAccount(funder: funder, signer: key);
    return ParseOrchidAccountResult(account: orchidAccount, newKeys: newKeys);
  }

  /// Resolve the key in an imported JSON hop, adding a 'keyRef' to the hop
  /// to the json.  If a new key is created it is added to the existingKeys list.
  static void _resolveImportedKeyFromJSON(
      dynamic hop,
      List<StoredEthereumKey> existingKeys,
      int nextKeyUid, // the uid to use for any newly created key
      List<StoredEthereumKey> newKeys) {
    var secret = hop['secret'];
    if (secret == null) {
      throw Exception("missing secret");
    }
    if (hop['keyRef'] != null) {
      throw Exception("keyRef in parsed json");
    }
    StoredEthereumKey key = _resolveImportedKey(secret, existingKeys, nextKeyUid, newKeys);
    hop['keyRef'] = key.ref().toString();
  }

  /// Find an imported key secret in existing keys or create a new key and
  /// add it to the newKeys list.  In both cases the key is returned.
  static StoredEthereumKey _resolveImportedKey(
      String secret,
      List<StoredEthereumKey> existingKeys,
      int nextKeyUid, // the uid to use for any newly created key
      List<StoredEthereumKey> newKeys) {
    if (secret == null) {
      throw Exception("missing secret");
    }
    secret = Hex.removePrefix(secret);
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
          uid: nextKeyUid.toString(),
          private: BigInt.parse(secret, radix: 16));
      newKeys.add(key);
      //print("parse: generated new key");
    }
    return key;
  }

  /// Import a new configuration file, replacing any existing configuration.
  /// Existing signer keys are unaffected.
  static Future<bool> importConfig(String config) async {
    var existingKeys = await UserPreferences().getKeys();
    var parsedCircuit = OrchidVPNConfig.parseCircuit(config, existingKeys);

    // Save any newly imported keys
    if (parsedCircuit.newKeys.length > 0) {
      print("Import added ${parsedCircuit.newKeys.length} new keys.");
      await UserPreferences().addKeys(parsedCircuit.newKeys);
    }

    // Save the imported circuit.
    await UserPreferences().setCircuit(parsedCircuit.circuit);
    print("Import saved ${parsedCircuit.circuit.hops.length} hop circuit.");
    OrchidAPI().circuitConfigurationChanged.add(null);
    return true;
  }

  static String _normalizeInputJSON(String text) {
    text = text.replaceAll("\n", " ");
    text = text.replaceAll("\r", " ");
    return text;
  }

  // Quote the keys in name-value key pairs, JSON style:
  //  [{curator: "partners.orch1d.eth",...  => [{"curator": "partners.orch1d.eth",...
  static String _quoteKeysJsonStyle(String text) {
    return text.replaceAllMapped(
        RegExp(r'([A-Za-z0-9_-]{1,})\s*:'), (Match m) => '"${m[1]}":');
  }

} // OrchidVPNConfig

typedef OrchidConfigValidator = bool Function(String config);

/// Validation logic for imported VPN configurations.
class OrchidVPNConfigValidation {
  /// Validate the orchid configuration.
  /// @See OrchidConfigValidator.
  static bool configValid(String config) {
    if (config == null || config == "") {
      return false;
    }
    try {
      var parsedCircuit =
          OrchidVPNConfig.parseCircuit(config, [] /*no existing keys*/);
      var circuit = parsedCircuit.circuit;
      return _isValidCircuitForImport(circuit);
    } catch (err, s) {
      print("invalid circuit: {$err}, $s");
      return false;
    }
  }

  // A few sanity checks
  static bool _isValidCircuitForImport(Circuit circuit) {
    return circuit.hops != null &&
        circuit.hops.length > 0 &&
        circuit.hops.every(_isValidHopForImport);
  }

  // A few sanity checks
  static bool _isValidHopForImport(CircuitHop hop) {
    if (hop is OrchidHop) {
      return hop.funder != null && hop.keyRef != null;
    }
    return true;
  }
}

/// Result holding a parsed circuit. Each hop has a keyRef referring to either
/// an existin key in the user's keystore or a newly imported but not yet saved
/// temporary key in the newKeys list.
class ParseCircuitResult {
  final Circuit circuit;
  final List<StoredEthereumKey> newKeys;

  ParseCircuitResult({this.circuit, this.newKeys});
}

// An Orchid account
class OrchidAccount {
  EthereumAddress funder;
  StoredEthereumKey signer;

  OrchidAccount({this.funder, this.signer});

}

/// Result holding a parsed imported Orchid account. The account signer key refers
/// to either an existin key in the user's keystore or a newly imported but not yet
/// saved temporary key in the newKeys list.
class ParseOrchidAccountResult {
  final OrchidAccount account;
  final List<StoredEthereumKey> newKeys;

  ParseOrchidAccountResult({this.account, this.newKeys});
}

