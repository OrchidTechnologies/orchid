import 'dart:async';
import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/vpn/model/circuit.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';

/// Support for importing the JavaScript configuration file used by the Orchid VPN.
// Note: The parsing in this class should be simplified using the (real) JSConfig parser.
class OrchidVPNConfigImport {
  /// Parse JavaScript config text optionally containing a variable assignment expression
  /// for `keys`.   Returns a list of new keys or an empty list.  e.g.
  ///   keys = [1234..., 1234...];
  static List<StoredEthereumKey> parseImportedKeysList(
      String js, List<StoredEthereumKey> existingKeys) {
    // Match a 'keys' variable assignment to a list of JS object literals:
    js = OrchidAccountImport.removeUnencodedNewlines(js);
    RegExp exp = RegExp(r'\s*[Kk][Ee][Yy][Ss]\s*=\s*\[(.*)]\s*;?\s*');
    var match = exp.firstMatch(js);
    if (match == null) {
      return [];
    }
    var secrets = (match.group(1) ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    var newKeys = <StoredEthereumKey>[];
    secrets.forEach((secret) {
      OrchidAccountImport.resolveImportedKey(secret, existingKeys, newKeys);
    });
    return newKeys;
  }

  /// Parse JavaScript config text containing a variable assignment expression for the `hops`
  /// configuration list and return the Circuit.  e.g.
  ///   hops = [{curator: "partners.orch1d.eth", protocol: "orchid", funder: "0x405bc10e04e3f487e9925ad5815e4406d78b769e", secret: "894643a2de07568a51f7fe59650365dea0e04376819ecff08e686face92ca16e"}];
  static ParseCircuitResult parseCircuit(
      String js, List<StoredEthereumKey> existingKeys) {
    // Note: It would be ideal to use our JSConfig JS parser to pull out the hops
    // here but ultimately we would want it in JSON to deserialize it and our
    // current JS parser cannot perform that conversion or even give us the text.

    // Match a 'hops' variable assignment to a list of JS object literals:
    // hops = [{curator: "partners.orch1d.eth",...
    // This regex matches 'hops = [ ... }];\n' and legal variations on that including
    // just the semicolon or just the newline.
    RegExp exp = RegExp(r'\s*[Hh][Oo][Pp][Ss]\s*=\s*(\[.*?}\s*\])\s*([;\n])',
        dotAll: true);
    var match = exp.firstMatch(js);
    var hopsString = match?.group(1);
    if (hopsString == null) {
      throw Exception("missing hops");
    }

    // Quote keys JSON style:
    //  [{curator: "partners.orch1d.eth",...  => [{"curator": "partners.orch1d.eth",...
    hopsString = OrchidAccountImport.quoteKeysJsonStyle(hopsString);

    // Decode the JSON
    // Wrap the top level JSON with a 'hops' key:
    // {"hops": [...]}
    Map<String, dynamic> json = {'hops': jsonDecode(hopsString)};

    // For Orchid hops:
    // Resolve imported secrets to existing stored keys or new temporary keys
    // Resolve chain and contract version.
    var tempKeys = <StoredEthereumKey>[];
    json['hops']
        .where((hop) =>
            ((hop['protocol'] ?? '') as String).contains(RegExp(r'orch[i1]d')))
        .forEach((hop) {
      _resolveImportedKeyFromJSON(hop, existingKeys, tempKeys);
      _resolveChainAndVersionFromJson(hop);
    });

    return ParseCircuitResult(
        circuit: Circuit.fromJson(json), newKeys: tempKeys);
  }

  /// Resolve the key in an imported JSON hop, adding a 'keyRef' to the hop
  /// to the json.  If a new key is created it is added to the existingKeys list.
  static void _resolveImportedKeyFromJSON(dynamic hop,
      List<StoredEthereumKey> existingKeys, List<StoredEthereumKey> newKeys) {
    var secret = hop['secret'];
    if (secret == null) {
      throw Exception("missing secret");
    }
    if (hop['keyRef'] != null) {
      throw Exception("keyRef in parsed json");
    }
    StoredEthereumKey key =
        OrchidAccountImport.resolveImportedKey(secret, existingKeys, newKeys);
    hop['keyRef'] = key.ref().toString();
  }

  /// Resolve the chain id and contract version
  /// For V0 legacy config chainid and version may be missing and will default.
  /// For V1 config whre a chainid is present we infer the version is 1 except
  /// in the case of main net where a currency of "ETH" indicates version 0.
  static void _resolveChainAndVersionFromJson(dynamic hop) {
    // Get the chain
    var chainId = hop['chainid'] ?? hop['chainId'] ?? 0; // accept either case
    hop['chainId'] = chainId; // convert to camel case

    // Infer the contract version
    var currency = hop['currency'];
    if (chainId == Chains.ETH_CHAINID &&
        currency.toString().toUpperCase() == "ETH") {
      hop['version'] = 0;
    } else {
      hop['version'] = 1;
    }
  }

  /// Import a new configuration file, replacing any existing configuration.
  /// Existing signer keys are unaffected.
  static Future<bool> importConfig(String config) async {
    var existingKeys = UserPreferencesKeys().keys.get()!;
    var parsedCircuit = parseCircuit(config, existingKeys);

    // Save any newly imported keys found in the circuit
    if (parsedCircuit.newKeys.isNotEmpty) {
      log("Import added ${parsedCircuit.newKeys.length} new keys.");
      await UserPreferencesKeys().addKeys(parsedCircuit.newKeys);
    }

    // Save the imported circuit.
    await UserPreferencesVPN().saveCircuit(parsedCircuit.circuit);

    log("Import saved ${parsedCircuit.circuit.hops.length} hop circuit.");

    // Parse the optional imported keys list.
    // First update the existing keys with any just imported above.
    existingKeys = UserPreferencesKeys().keys.get()!;
    var newKeys = parseImportedKeysList(config, existingKeys);
    if (newKeys.isNotEmpty) {
      log("Imported keys list added ${newKeys.length} new keys.");
      await UserPreferencesKeys().addKeys(newKeys);
    }

    return true;
  }
} // OrchidVPNConfig

typedef OrchidConfigValidator = bool Function(String config);

/// Validation logic for imported VPN configurations containing full circuits.
class OrchidVPNConfigValidationV0 {
  /// Validate the orchid configuration.
  /// @See OrchidConfigValidator.
  static bool configValid(String? config) {
    if (config == null || config == "") {
      return false;
    }
    try {
      var parsedCircuit =
          OrchidVPNConfigImport.parseCircuit(config, [] /*no existing keys*/);
      var circuit = parsedCircuit.circuit;
      return _isValidCircuitForImport(circuit);
    } catch (err, s) {
      print("invalid circuit: {$err}, $s");
      return false;
    }
  }

  // A few sanity checks
  static bool _isValidCircuitForImport(Circuit circuit) {
    return //circuit.hops != null &&
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
/// an existing key in the user's keystore or a newly imported but not yet saved
/// temporary key in the newKeys list.
class ParseCircuitResult {
  final Circuit circuit;
  final List<StoredEthereumKey> newKeys;

  ParseCircuitResult({required this.circuit, required this.newKeys});
}
