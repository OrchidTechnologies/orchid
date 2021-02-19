import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/util/hex.dart';

import '../../orchid_api.dart';
import '../../orchid_log_api.dart';

/// Support for reading and generating the JavaScript configuration file used by the Orchid VPN.
// Note: The parsing in this class should be simplified using the (real) JSConfig parser.
class OrchidVPNConfigV0 {
  /// Generate the circuit hops list portion of the VPN config managed by the UI.
  /// The desired format is a JavaScript object literal assignment, e.g.:
  /// hops = [{protocol: "orchid", secret: "HEX", funder: "0xHEX"}, {protocol: "orchid", secret: "HEX", funder: "0xHEX"}];
  static Future<String> generateConfig() async {
    Circuit circuit = await UserPreferences().getCircuit();
    List<StoredEthereumKey> keys = await UserPreferences().getKeys();
    List<CircuitHop> hops = circuit?.hops ?? [];

    /// Convert each hop to a json map and replace values as required by the rendered config.
    var hopsListConfig = hops.map((hop) {
      // To JSON
      var hopJson = hop.toJson();

      // Resolve key references
      var resolvedKeysHop = resolveKeyReferencesForExport(hopJson, keys);

      // Perform any needed transformations on the individual key/values in the json.
      return toConfigJS(resolvedKeysHop);
    }).toList();

    return "hops = $hopsListConfig;";
  }

  /// Render a map to a JS literal with un-quoted keys (not JSON) and quoted values.
  static String toConfigJS(Map<String, dynamic> map) {
    return map.map((String key, dynamic value) {
      // The protocol value is transformed to lowercase.
      if (key == 'protocol') {
        value = value.toString().toLowerCase();
      }
      // Escape newlines in string values
      if (value is String) {
        value = value.replaceAll('\n', '\\n');
      }
      // Quote all values except for numbers
      return MapEntry(key, (value is int) ? value : "\"$value\"");
    }).toString();
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
            secret = key.formatSecretFixed();
          } catch (err) {
            log("resolveKeyReferences invalid key ref: $keyRef");
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
  /// TODO: For now we are transforming the JS object literal into JSON for parsing.
  /// TODO: We should update this to use our JSConfig (real) JS parser.
  static ParseCircuitResultV0 parseCircuit(
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

    return ParseCircuitResultV0(
        circuit: Circuit.fromJson(json), newKeys: tempKeys);
  }

  /// Parse an imported Orchid account from JS (input text containing a valid account assignment).
  /// TODO: We should update this to use our JSConfig (real) JS parser.
  static ParseOrchidAccountResultV0 parseOrchidAccount(
      String js, List<StoredEthereumKey> existingKeys) {
    // Remove newlines, etc.
    js = _normalizeInputJSON(js);

    // Match an 'account' variable assignment to a JS object literal:
    // 'account = {protocol:"orchid",funder:"0x2Be...",secret:"0xfb5d5..."}'
    RegExp exp =
        RegExp(r'\s*[Aa][Cc][Cc][Oo][Uu][Nn][Tt]\s*=\s*(\{.*\})\s*;?\s*');
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
    String curator = json['curator'];

    // Resolve imported secrets to existing stored keys or new temporary keys
    var newKeys = List<StoredEthereumKey>();
    var uid = DateTime.now().millisecondsSinceEpoch;
    StoredEthereumKey key =
        _resolveImportedKey(secret, existingKeys, uid, newKeys);
    var orchidAccount =
        OrchidAccountV0(curator: curator, funder: funder, signer: key);
    return ParseOrchidAccountResultV0(account: orchidAccount, newKeys: newKeys);
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
    StoredEthereumKey key =
        _resolveImportedKey(secret, existingKeys, nextKeyUid, newKeys);
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
    var parsedCircuit = parseCircuit(config, existingKeys);

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

  /// Create a hop from an account parse result, save any new keys, and return the hop
  /// to the add flow completion.
  static Future<CircuitHop> importAccountAsHop(
      ParseOrchidAccountResultV0 result) async {
    print(
        "result: ${result.account.funder}, ${result.account.signer}, new keys = ${result.newKeys.length}");
    // Save any new keys
    await UserPreferences().addKeys(result.newKeys);
    // Create the new hop
    CircuitHop hop = OrchidHop(
      curator: result.account.curator ?? OrchidHop.appDefaultCurator,
      funder: result.account.funder,
      keyRef: result.account.signer.ref(),
    );
    return hop;
  }
} // OrchidVPNConfig

typedef OrchidConfigValidator = bool Function(String config);

/// Validation logic for imported VPN configurations.
class OrchidVPNConfigValidationV0 {
  /// Validate the orchid configuration.
  /// @See OrchidConfigValidator.
  static bool configValid(String config) {
    if (config == null || config == "") {
      return false;
    }
    try {
      var parsedCircuit =
          OrchidVPNConfigV0.parseCircuit(config, [] /*no existing keys*/);
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
class ParseCircuitResultV0 {
  final Circuit circuit;
  final List<StoredEthereumKey> newKeys;

  ParseCircuitResultV0({this.circuit, this.newKeys});
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
/// to either an existin key in the user's keystore or a newly imported but not yet
/// saved temporary key in the newKeys list.
class ParseOrchidAccountResultV0 {
  final OrchidAccountV0 account;
  final List<StoredEthereumKey> newKeys;

  ParseOrchidAccountResultV0({this.account, this.newKeys});
}
