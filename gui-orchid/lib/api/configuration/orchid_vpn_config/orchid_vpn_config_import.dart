import 'dart:async';
import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/circuit/circuit_page.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import '../../orchid_api.dart';
import 'orchid_account_import.dart';

/// Support for importing the JavaScript configuration file used by the Orchid VPN.
// Note: The parsing in this class should be simplified using the (real) JSConfig parser.
class OrchidVPNConfigImport {

  /// Parse JavaScript text containing a variable assignment expression for the `hops`
  /// configuration list and return the Circuit.  e.g.
  ///   hops = [{curator: "partners.orch1d.eth", protocol: "orchid", funder: "0x405bc10e04e3f487e9925ad5815e4406d78b769e", secret: "894643a2de07568a51f7fe59650365dea0e04376819ecff08e686face92ca16e"}];
  /// TODO: For now we are transforming the JS object literal into JSON for parsing.
  /// TODO: We should update this to use our JSConfig (real) JS parser.
  static ParseCircuitResult parseCircuit(String js,
      List<StoredEthereumKey> existingKeys) {
    // Remove newlines, etc.
    js = OrchidAccountImport.normalizeInputJSON(js);

    // Match a 'hops' variable assignment to a list of JS object literals:
    // hops = [{curator: "partners.orch1d.eth",...
    RegExp exp = RegExp(r'\s*[Hh][Oo][Pp][Ss]\s*=\s*(\[.*\])\s*;?\s*');
    var match = exp.firstMatch(js);
    var hopsString = match.group(1);

    // Quote keys JSON style:
    //  [{curator: "partners.orch1d.eth",...  => [{"curator": "partners.orch1d.eth",...
    hopsString = OrchidAccountImport.quoteKeysJsonStyle(hopsString);

    // Wrap the top level JSON with a 'hops' key:
    // {"hops": [...]}
    hopsString = '{"hops": $hopsString}';

    // Decode the JSON
    Map<String, dynamic> json = jsonDecode(hopsString);

    // For Orchid hops:
    // Resolve imported secrets to existing stored keys or new temporary keys
    // Resolve chain and contract version.
    var tempKeys = <StoredEthereumKey>[];
    json['hops']
        .where((hop) => hop['protocol'] == "orchid")
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
    var chainId = hop['chainid'] ?? hop['chainId']; // accept either case
    hop['chainId'] = chainId; // convert to camel case

    // Infer the contract version
    var currency = hop['currency'];
    if (chainId == Chains.ETH_CHAINID && currency.toString().toUpperCase() == "ETH") {
      hop['version'] = 0;
    } else {
      hop['version'] = 1;
    }
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
    await CircuitUtils.saveCircuit(parsedCircuit.circuit);
    print("Import saved ${parsedCircuit.circuit.hops.length} hop circuit.");
    return true;
  }

} // OrchidVPNConfig

typedef OrchidConfigValidator = bool Function(String config);

/// Validation logic for imported VPN configurations containing full circuits.
class OrchidVPNConfigValidationV0 {
  /// Validate the orchid configuration.
  /// @See OrchidConfigValidator.
  static bool configValid(String config) {
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
/// an existing key in the user's keystore or a newly imported but not yet saved
/// temporary key in the newKeys list.
class ParseCircuitResult {
  final Circuit circuit;
  final List<StoredEthereumKey> newKeys;

  ParseCircuitResult({this.circuit, this.newKeys});
}
