// @dart=2.12
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/js_config.dart';

/// Import orchid accounts
class OrchidAccountImport {
  /// Parse an account config from JavaScript (not JSON), e.g.
  /// account = {
  ///   version: 1,
  ///   secret:"0xfb5d5...",
  ///   funder: "0x1234...",
  ///   chainid: 100,
  /// }
  static ParseOrchidIdentityOrAccountResult parseOrchidAccount(
      String js, List<StoredEthereumKey> existingKeys) {
    try {
      // signer
      final config = JSConfig(js);
      var secret = config.evalString('account.secret');
      var newKeys = <StoredEthereumKey>[]; // type required here
      var signer = resolveImportedKey(secret, existingKeys, newKeys);
      log("XXX signer = $signer");

      // account info
      final String? funder = config.evalStringDefault('account.funder', null);
      if (funder != null) {
        final version = config.evalIntDefault('account.version', 1);
        final chainid = config.evalIntDefault('account.chainid', 1);
        final account = Account.fromSignerKey(
          signerKey: signer.ref(),
          funder: EthereumAddress.from(funder),
          version: version,
          chainId: chainid,
        );
        final accountIsNew =
            !UserPreferences().cachedDiscoveredAccounts.get().contains(account);
        return ParseOrchidIdentityOrAccountResult(
          signer: signer,
          isSignerNew: newKeys.isNotEmpty,
          account: account,
          isAccountNew: accountIsNew,
        );
      } else {
        return ParseOrchidIdentityOrAccountResult(
          signer: signer,
          isSignerNew: newKeys.isNotEmpty,
        );
      }
    } catch (err) {
      print("Error parsing orchid account: $err");
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
      throw Exception("Invalid key");
    }
    try {
      var newKeys = <StoredEthereumKey>[];
      var signer = resolveImportedKey(secret, existingKeys, newKeys);
      return ParseOrchidIdentityOrAccountResult(
          signer: signer, isSignerNew: newKeys.isNotEmpty);
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

  static String removeNewlines(String text) {
    text = text.replaceAll('\n', ' ');
    text = text.replaceAll('\r', ' ');
    return text;
  }

  // Quote the keys in name-value key pairs, JSON style:
  //  [curator: "partners.orch1d.eth",...  => ["curator": "partners.orch1d.eth",...
  static String quoteKeysJsonStyle(String text) {
    return text.replaceAllMapped(
        RegExp(r'([A-Za-z0-9_-]{1,})\s*:'), (Match m) => '"${m[1]}":');
  }
}

/// A valid parse result will include at least a signer key and an indication
/// of whether the signer key is new or resolved to an existing (saved) key.
/// The parse may optionally include full account info (version, funder, chain)
/// referencing the included signer.
class ParseOrchidIdentityOrAccountResult {
  /// The parsed signer key, which may or may not be new.
  final StoredEthereumKey signer;

  /// The signer is new and is not yet saved.
  final bool isSignerNew;

  /// A parsed account referencing the above signer key.
  /// Null if no account information was included in the parse.
  final Account? account;

  /// The account is new and not yet saved.
  final bool isAccountNew;

  bool get isNew => isSignerNew || isAccountNew;

  ParseOrchidIdentityOrAccountResult({
    required this.signer,
    required this.isSignerNew,
    this.account,
    this.isAccountNew = false,
  });

  static ParseOrchidIdentityOrAccountResult parse(String config,
      {List<StoredEthereumKey>? keys}) {
    final existingKeys = keys ?? UserPreferences().keys.get();

    // Parse an account or identity (full account or signer key only).
    try {
      return OrchidAccountImport.parseOrchidAccount(config, existingKeys);
    } catch (err) {
      // fall through to next test
    }

    // Try to parse as a raw hex signer key
    return OrchidAccountImport.parseRawKey(config, existingKeys);
  }

  Future<void> save() async {
    saveIfNeeded();
  }

  Future<void> saveIfNeeded() async {
    if (isSignerNew) {
      await UserPreferences().addKey(signer);
    }
    // https://stackoverflow.com/questions/65456958/dart-null-safety-doesnt-work-with-class-fields/65457221#65457221
    if (account != null && isAccountNew) {
      await UserPreferences().addCachedDiscoveredAccounts([account!]);
    }
  }

  @override
  String toString() {
    return 'ParseOrchidIdentityOrAccountResult{signer: $signer, isSignerNew: $isSignerNew, account: $account, isAccountNew: $isAccountNew}';
  }
}
