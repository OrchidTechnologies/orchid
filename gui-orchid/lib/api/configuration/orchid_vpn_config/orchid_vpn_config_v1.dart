import 'dart:async';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/account_manager/account_store.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import '../js_config.dart';
import 'orchid_vpn_config_v0.dart';

/// Support for reading and generating the JavaScript configuration file used by the Orchid VPN.
class OrchidVPNConfigV1 {
  /// Generate the circuit hops list portion of the VPN config managed by the UI.
  /// The desired format is a JavaScript object literal assignment, e.g.:
  /// hops = [{protocol: "orchid", secret: "HEX", funder: "0xHEX"}];
  static Future<String> generateConfig() async {
    var accountStore = await AccountStore(discoverAccounts: false).load();
    Account account = accountStore.activeAccount;

    if (account == null || account.isIdentityPlaceholder) {
      return "hops = [];";
    }

    var signerKey = accountStore.activeIdentity;
    var funder = account.funder;
    var chain = account.chain;
    var curator = await UserPreferences().getDefaultCurator() ??
        OrchidHop.appDefaultCurator;

    var config;
    if (account.version == 0) {
      config =
          OrchidHop(funder: funder, keyRef: signerKey.ref(), curator: curator)
              .toJson();
      config = OrchidVPNConfigV0.resolveKeyReferencesForExport(
          config, accountStore.identities);
    } else {
      /*
      hops = [{
        protocol = 'orch1d';
        chainid = 56;
        currency = 'BNB';
        rpc = "https://bsc-dataseed.binance.org/";
        curator: "partners.orch1d.eth",
        funder: "0x6ddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx85087",
        secret: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx7a5b63bca512952325",
      }];
     */
      config = {
        'protocol': 'orch1d', // leet!
        'chainid': chain.chainId,
        'currency': chain.nativeCurrency.orchidConfigSymbol ??
            chain.nativeCurrency.symbol,
        'rpc': chain.providerUrl,
        'curator': curator,
        'funder': funder,
        'secret': signerKey.formatSecretFixed(),
      };
    }

    var hopConfig = OrchidVPNConfigV0.toConfigJS(config);
    return "hops = [$hopConfig];";
  }

  /// Parse a V1 account identity config.
  // e.g. 'account = {secret:"0xfb5d5..."}'
  static ParseOrchidIdentityResult parseOrchidIdentity(
      String js, List<StoredEthereumKey> existingKeys) {
    try {
      var config = JSConfig(js);
      var secret = config.evalString('account.secret');
      var newKeys = <StoredEthereumKey>[]; // type required here
      var signer =
          OrchidVPNConfigV0.resolveImportedKey(secret, existingKeys, newKeys);
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
  final ParseOrchidIdentityResult identity;
  final ParseOrchidAccountResultV0 account;

  ParseOrchidAccountResult({this.identity, this.account});

  static Future<ParseOrchidAccountResult> parse(
    String config, {
    List<StoredEthereumKey> keys,
    bool v0Only = false, // If true only V0 account strings will be valid
  }) async {
    var existingKeys = keys ?? await UserPreferences().getKeys();

    // Try to parse as a V0 account
    try {
      return ParseOrchidAccountResult(
          account: OrchidVPNConfigV0.parseOrchidAccount(config, existingKeys));
    } catch (err) {
      if (v0Only) {
        throw err;
      }
    }

    // Try to parse as a V1 identity (which may be a subset of a V0 account)
    return ParseOrchidAccountResult(
        identity: OrchidVPNConfigV1.parseOrchidIdentity(config, existingKeys));
  }

  @override
  String toString() {
    return 'ParseOrchidAccountResult{identity: $identity, account: $account}';
  }
}
