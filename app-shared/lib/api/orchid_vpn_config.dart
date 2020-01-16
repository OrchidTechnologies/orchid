import 'dart:async';
import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';

import 'orchid_api.dart';

// TODO: Add unit tests.
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
      var resolvedHop = resolveKeyReferences(hop.toJson(), keys);
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
  static Map<String, dynamic> resolveKeyReferences(
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
            print("existing key refs: ");
            for (var key in keys) {
              print("keyref = ${key.uid}");
            }
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
  /// Note: It would be better if we had a real JS parser at our disposal.  For now we are
  /// Note: transforming the JS object literal into JSON.
  /// Note: Consider porting the `acorn.js` embeddable JS interpreter:
  /// Note: https://github.com/NeilFraser/JS-Interpreter
  static ParseCircuitResult parseCircuit(
      String js, List<StoredEthereumKey> existingKeys) {
    js = js.replaceAll("\n", " ");
    js = js.replaceAll("\r", " ");

    // Match a 'hops' variable assignment to a list of JS object literals:
    // hops = [{curator: "partners.orch1d.eth",...
    RegExp exp = RegExp(r'\s*[Hh][Oo][Pp][Ss]\s*=\s*(\[.*\])\s*;?\s*');
    var match = exp.firstMatch(js);
    var hopsString = match.group(1);

    // Quote keys, JSON style:
    //  [{curator: "partners.orch1d.eth",...  => [{"curator": "partners.orch1d.eth",...
    hopsString = hopsString.replaceAllMapped(
        RegExp(r'([A-Za-z0-9]{1,})\s*:'), (Match m) => '"${m[1]}":');

    // Wrap the top level JSON:
    // {"hops": [...]}
    hopsString = '{"hops": $hopsString}';

    // Convert to JSON
    Map<String, dynamic> json = jsonDecode(hopsString);

    // Resolve secrets to existing stored keys or new temporary keys
    var tempKeys = List<StoredEthereumKey>();
    var uid = DateTime.now().millisecondsSinceEpoch;
    json['hops'].asMap().forEach((index, hop) {
      // Only interested in Orchid hops here
      if (hop['protocol'] != "orchid") {
        return;
      }

      var secret = hop['secret'];
      if (secret == null) {
        throw Exception("missing secret");
      }
      if (hop['keyRef'] != null) {
        throw Exception("keyRef in parsed json");
      }
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
            uid: (uid + index).toString(),
            private: BigInt.parse(secret, radix: 16));
        tempKeys.add(key);
        //print("parse: generated new key");
      }
      hop['keyRef'] = key.ref().toString();
    });

    return ParseCircuitResult(
        circuit: Circuit.fromJson(json), newKeys: tempKeys);
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
}

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

/// Result holding a parsed circuit and temporary keys referenced in its hops.
/// Keys are suitable for saving to the user's keystore but should be reconciled
/// first with any previously stored key values.
class ParseCircuitResult {
  final Circuit circuit;
  final List<StoredEthereumKey> newKeys;

  ParseCircuitResult({this.circuit, this.newKeys});
}
