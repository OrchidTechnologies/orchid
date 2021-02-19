import 'dart:async';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/account_manager/account_store.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'orchid_vpn_config_v0.dart';

/// Support for reading and generating the JavaScript configuration file used by the Orchid VPN.
class OrchidVPNConfigV1 {
  /// Generate the circuit hops list portion of the VPN config managed by the UI.
  /// The desired format is a JavaScript object literal assignment, e.g.:
  /// hops = [{protocol: "orchid", secret: "HEX", funder: "0xHEX"}];
  static Future<String> generateConfig() async {
    var accountStore = await AccountStore().load();
    Account account = accountStore.activeAccount;
    log("XXX: active account = $account");

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
} // OrchidVPNConfig
