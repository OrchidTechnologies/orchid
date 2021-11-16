import 'dart:async';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import '../../orchid_log_api.dart';

class OrchidVPNConfigGenerate {
  /// Generate the circuit hops list portion of the VPN config managed by the UI.
  /// The desired format is a JavaScript object literal assignment, e.g.:
  /// hops = [{protocol: "orchid", secret: "xxx", funder: "0xaaa"}, ...]
  ///
  /// If forExport is true the generated config will exclude any non-importable
  /// (strictly inferred) fields such as the chain RPC endpoint.  The 'currency'
  /// field may, while inferrable from chainid, is used to infer the contract
  /// version on main net during import.
  static Future<String> generateConfig({
    bool forExport = false,
  }) async {
    Circuit circuit = await UserPreferences().circuit.get();
    List<StoredEthereumKey> keys = await UserPreferences().keys.get();
    List<CircuitHop> hops = circuit?.hops ?? [];

    var hopsConfig = await Future.wait(hops.map((hop) {
      return _hopToConfig(hop, keys, forExport);
    }));
    return "hops = $hopsConfig;";
  }

  /// Convert a hop to a json map and replace values as required by the rendered config.
  static Future<String> _hopToConfig(
    CircuitHop hop,
    List<StoredEthereumKey> keys,
    bool forExport,
  ) async {
    // To JSON
    var hopConfigJson = hop.protocol == HopProtocol.Orchid
        ? await _orchidHopToConfigJson(hop, keys, forExport)
        : hop.toJson();

    // Resolve key references
    var resolvedKeysHop = resolveKeyReferencesForExport(hopConfigJson, keys);

    // Convert the hop JSON description to Orchid config formatted JS.
    return toConfigJS(resolvedKeysHop);
  }

  /// Render the hop to a json map of config values.
  static Future<Map<String, dynamic>> _orchidHopToConfigJson(
    OrchidHop hop,
    List<StoredEthereumKey> keys,
    bool forExport,
  ) async {
    /*
      hops = [{
        curator: 'partners.orch1d.eth',
        protocol = 'orchid' || 'orch1d',
        funder: '0x6ddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx85087',
        secret: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx7a5b63bca512952325',

        // v1
        chainid = 56,
        currency = 'BNB',
        rpc = 'https://bsc-dataseed.binance.org/',
      }];
     */
    var v0 = hop.account.isV0;
    var protocol = v0 ? 'orchid' : 'orch1d'; // leety!
    var signerKey = await hop.account.signerKey;
    var funder = hop.account.funder;
    var curator = hop.curator ??
        (await UserPreferences().getDefaultCurator()) ??
        OrchidHop.appDefaultCurator;

    // V0 fields
    var hopConfigJson = {
      'protocol': protocol,
      'curator': curator,
      'funder': funder,
      'secret': signerKey.formatSecretFixed(),
    };

    var chain = hop.account.chain;
    var currency = chain.nativeCurrency.exchangeRateSource.symbolOverride ??
        chain.nativeCurrency.symbol;

    // V1 fields
    if (!v0) {
      hopConfigJson.addAll({
        'chainid': chain.chainId,
        'currency': currency,
        'rpc': chain.providerUrl,
      });
    }

    // Filter out non-export fields
    if (forExport) {
      hopConfigJson.remove('rpc');
    }

    return hopConfigJson;
  }

  /// Replace JSON "keyRef" key references with private key "secret" values.
  static Map<String, dynamic> resolveKeyReferencesForExport(
      Map<String, dynamic> json, List<StoredEthereumKey> keys) {
    return json.map((String key, dynamic value) {
      // Key references are replaced with the actual key values.
      if (key == "keyRef") {
        String secret;
        if (value != null) {
          var keyRef = StoredEthereumKeyRef(value);
          try {
            StoredEthereumKey key = keyRef.getFrom(keys);
            secret = key.formatSecretFixed();
          } catch (err) {
            log("resolveKeyReferences invalid key ref: $keyRef");
          }
        } else {
          secret = null;
        }
        return MapEntry('secret', secret);
      }
      return MapEntry(key, value);
    });
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
}
