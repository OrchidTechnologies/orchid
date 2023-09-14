import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/vpn/orchid_vpn_config/js_config.dart';

/// Import orchid accounts
class OrchidAccountImport {
  static ParseOrchidIdentityOrAccountResult parse(String config,
      {List<StoredEthereumKey>? keys}) {
    final existingKeys = keys ?? UserPreferencesKeys().keys.get()!;

    // Try multiple full accounts
    try {
      return OrchidAccountImport.parseMultipleOrchidAccounts(
          config, existingKeys);
    } catch (err) {
      // fall through to next test
    }

    // Try a full account or standalone identity
    try {
      return OrchidAccountImport.parseSingleOrchidAccount(config, existingKeys);
    } catch (err) {
      // fall through to next test
      log("Error parsing single orchid account: $err");
    }

    // Try a raw hex signer key
    return OrchidAccountImport.parseRawKey(config, existingKeys);
  }

  /// Parse one or more account configs from JavaScript (not JSON), e.g.
  /// accounts = [
  ///   {
  ///     secret:"0xfb5d5...",
  ///     funder: "0x1234...",
  ///     version: 1,
  ///     chainid: 100,
  ///   },
  ///   {
  ///     secret:"0xeb5d5...",
  ///     funder: "0x2235...",
  ///     version: 1,
  ///     chainid: 100,
  ///   },
  /// ]
  static ParseOrchidIdentityOrAccountResult parseMultipleOrchidAccounts(
      String js, List<StoredEthereumKey> existingKeys) {
    try {
      // signer info
      final config = JSConfig(js);
      var accountsJs = config.evalObject('accounts');
      final accounts = accountsJs.map<Account>((account) {
        if (account == null) {
          throw "Account is null";
        }
        final secret = account['secret'].toString();
        final signer = resolveImportedKey(secret, existingKeys, []);
        final funder =
            EthereumAddress.from(account['funder'].toString());
        final version = account['version'];
        final chainid = account['chainid'];
        return Account.fromSignerKey(
          signerKey: signer,
          funder: funder,
          version: version,
          chainId: chainid,
        );
      }).toList();
      return ParseOrchidIdentityOrAccountResult(accounts: accounts);
    } catch (err) {
      // print("Error parsing orchid accounts: $err");
      throw err;
    }
  }

  /// Parse a singular signer key or account config from JavaScript (not JSON), e.g.
  /// account = {
  ///   version: 1,
  ///   secret:"0xfb5d5...",
  ///   funder: "0x1234...",
  ///   chainid: 100,
  /// }
  static ParseOrchidIdentityOrAccountResult parseSingleOrchidAccount(
      String js, List<StoredEthereumKey> existingKeys) {
    try {
      // signer info
      final config = JSConfig(js);
      var secret = config.evalString('account.secret');
      if (secret == null) {
        throw "Account secret is null";
      }
      var newKeys = <StoredEthereumKey>[]; // type required here
      var signer = resolveImportedKey(secret, existingKeys, newKeys);

      // has account info
      final String? funder = config.evalStringDefaultNull('account.funder');
      if (funder != null) {
        final version = config.evalIntDefault('account.version', 1);
        final chainid = config.evalIntDefault('account.chainid', 1);
        final account = Account.fromSignerKeyRef(
          signerKey: signer.ref(),
          funder: EthereumAddress.from(funder),
          version: version,
          chainId: chainid,
        );
        // final accountIsNew = !UserPreferences().cachedDiscoveredAccounts.get().contains(account);
        return ParseOrchidIdentityOrAccountResult(accounts: [account]);
      } else {
        return ParseOrchidIdentityOrAccountResult(signerOptional: signer);
      }
    } catch (err) {
      // print("Error parsing orchid account: $err");
      throw err;
    }
  }

  /// Parse a 64 character raw hex encoded key with leading zeroes if required.
  /// The string may optionally be prefixed with "0x" making it 66 characters.
  /// The string is trimmed and case is ignored.
  static ParseOrchidIdentityOrAccountResult parseRawKey(
      String secretIn, List<StoredEthereumKey> existingKeys) {
    var secret = secretIn.toLowerCase().trim();
    RegExp hexEncodedSecret = RegExp(r'^(0x)?[a-f0-9]{64}$');
    if (!hexEncodedSecret.hasMatch(secret)) {
      throw Exception("Invalid key: $secret");
    }
    try {
      var newKeys = <StoredEthereumKey>[];
      var signer = resolveImportedKey(secret, existingKeys, newKeys);
      return ParseOrchidIdentityOrAccountResult(signerOptional: signer);
    } catch (err) {
      print("Error parsing orchid identity: $err");
      throw err;
    }
  }

  /// Find an imported key secret in existing keys or create a new key and
  /// add it to the newKeys list.  In both cases the key is returned.
  static StoredEthereumKey resolveImportedKey(String secret,
      List<StoredEthereumKey> existingKeys, List<StoredEthereumKey> newKeys) {
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

  static String removeUnencodedNewlines(String text) {
    text = text.replaceAll('\n', ' ');
    text = text.replaceAll('\r', ' ');
    return text;
  }

  // Quote the keys in name-value key pairs, JSON style:
  //  [curator: "partners.orch1d.eth",...  => ["curator": "partners.orch1d.eth",...
  // Should handle the colons in this example:
  // in:  [{ protocol: "openvpn", ovpnfile: "test", url: "http://foo:1234", foo: 132 }];
  // out: [{ "protocol": "openvpn", "ovpnfile": "test", "url": "http://foo:1234", "foo": 132 }];
  static String quoteKeysJsonStyle(String input) {
    StringBuffer result = StringBuffer();
    bool insideQuotes = false;
    bool isKey = false;
    StringBuffer keyBuffer = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      var char = input[i];

      if (char == '"') {
        insideQuotes = !insideQuotes;
      }

      // If outside quotes and encountering a new object or pair, it must be a key
      if (!insideQuotes && (char == '{' || char == ',')) {
        isKey = true;
      }

      // If in a key, write the character to keyBuffer unless it's a special character
      if (isKey && char.trim().isNotEmpty && !': {,'.contains(char)) {
        keyBuffer.write(char);
      } else {
        // If we've built up a key and encounter a colon, write the quoted key
        if (keyBuffer.isNotEmpty && char == ':') {
          result.write('"' + keyBuffer.toString() + '"');
          keyBuffer.clear();
        }
        result.write(char);
        if (char == ':') {
          isKey = false;
        }
      }
    }

    return result.toString();
  }
}

/// The result of a valid parse of an orchid key or account config.
/// The result includes either an identity (signer key) or a list of one or
/// more accounts (signer key, version, funder, chain)
/// Note that the accounts returned reference transient keys that have not yet
/// been saved but can be access through the account.
class ParseOrchidIdentityOrAccountResult {
  /// The parsed signer key, which may or may not be new.
  /// Null if a list of accounts was included in the parse.
  final StoredEthereumKey? signerOptional; // rename?

  /// One or more parsed accounts
  /// Null if no account information was included in the parse.
  final List<Account>? accounts;

  bool get hasMultipleAccounts {
    return (accounts ?? []).length > 1;
  }

  ParseOrchidIdentityOrAccountResult({
    this.signerOptional,
    this.accounts,
  }) {
    // assert(signerOptional != null || accounts != null);
  }

  // Migration: Return either the imported signer or the signer of the first
  // imported account
  StoredEthereumKey get signer {
    return signerOptional ?? accounts![0].signerKey;
  }

  // Migration: Return either the first imported account or null.
  Account? get account {
    return accounts != null ? accounts![0] : null;
  }

  Future<void> save() async {
    saveIfNeeded();
  }

  Future<void> saveIfNeeded() async {
    if (signerOptional != null) {
      await UserPreferencesKeys().addKeyIfNeeded(signerOptional!);
    }
    if (accounts != null) {
      // https://stackoverflow.com/questions/65456958/dart-null-safety-doesnt-work-with-class-fields/65457221#65457221
      saveAccountsIfNeeded(accounts ?? []);
    }
  }

  static Future<void> saveAccountsIfNeeded(Iterable<Account> accounts) async {
    for (var account in (accounts)) {
      await UserPreferencesKeys().addKeyIfNeeded(account.signerKey);
    }
    await UserPreferencesVPN().addAccountsIfNeeded(accounts.toList());
  }

  @override
  String toString() {
    return 'ParseOrchidIdentityOrAccountResult{\nsigner: $signerOptional, \naccounts: $accounts}';
  }
}
