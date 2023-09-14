import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';

class OrchidHop extends CircuitHop {
  // The app default, which may be overridden by the user specified settings
  // default or on a per-hop basis.
  static const String appDefaultCurator = 'partners.orch1d.eth';

  /// Curator URI
  final String? curator;

  /// Signer key uid
  final StoredEthereumKeyRef? keyRef;

  /// Funder address
  final EthereumAddress? funder;

  /// The contract version: 0 for the original OXT contract.
  final int? version;

  /// The contract version: 1 for Ethereum for the original OXT contract.
  final int? chainId;

  // This transient field supports testing without stored keys.
  EthereumAddress? resolvedSignerAddress;

  /// The Orchid Account associated with this hop.
  // Note: This is a migration from the v0 storage and should eventually replace it.
  Account get account {
    if (funder == null || version == null || chainId == null) {
      throw Exception('Missing required fields for Orchid Account');
    }
    return Account.base(
      signerKeyUid: keyRef?.keyUid,
      funder: funder!,
      version: version!,
      chainId: chainId!,
      resolvedSignerAddress: resolvedSignerAddress,
    );
  }

  OrchidHop({
    required this.curator,
    required this.funder,
    required this.keyRef,
    required this.version,
    required this.chainId,
    this.resolvedSignerAddress,
  }) : super(HopProtocol.Orchid);

  OrchidHop.fromAccount(Account account)
      : this(
          curator: appDefaultCurator,
          funder: account.funder,
          keyRef: account.hasKey ? account.signerKeyRef : null,
          version: account.version,
          chainId: account.chainId,
          resolvedSignerAddress: account.resolvedSignerAddress,
        );

  OrchidHop.v0({
    required this.curator,
    required this.funder,
    required this.keyRef,
  })  : this.version = 0,
        this.chainId = Chains.ETH_CHAINID,
        super(HopProtocol.Orchid);

  // Construct an Orchid Hop using an existing hop's properties as defaults.
  // The hop may be null, in which case this serves as a loose constructor.
  OrchidHop.from(
    OrchidHop? hop, {
    String? curator,
    EthereumAddress? funder,
    StoredEthereumKeyRef? keyRef,
    int? version,
    int? chainId,
  }) : this(
          curator: curator ?? hop?.curator,
          funder: funder ?? hop?.funder,
          keyRef: keyRef ?? hop?.keyRef,
          version: version ?? hop?.version,
          chainId: chainId ?? hop?.chainId,
        );

  OrchidHop.fromJson(Map<String, dynamic> json)
      : this.curator = json['curator'] ?? appDefaultCurator,
        this.funder = EthereumAddress.from(json['funder']),
        this.keyRef = StoredEthereumKeyRef(json['keyRef']),

        // Migrate version from legacy v0 if null
        this.version = json['version'] ?? 0,
        // Migrate chainId from legacy v0 if null
        this.chainId = json['chainId'] ?? Chains.ETH_CHAINID,
        super(HopProtocol.Orchid);

  Map<String, dynamic> toJson() => {
        'curator': curator,
        'protocol': CircuitHop.protocolToString(protocol),
        // Always render funder with the hex prefix as required by the config.
        'funder': funder?.toString(prefix: true),
        'keyRef': keyRef.toString(),
        'version': version,
        'chainId': chainId,
      };

  /// Return key uids for configured hops
  static Future<List<String>> getInUseKeyUids() async {
    // Get the active hop keys
    var activeHops = UserPreferencesVPN().circuit.get()!.hops;
    List<OrchidHop> activeOrchidHops =
        activeHops.where((h) => h is OrchidHop).cast<OrchidHop>().toList();
    List<StoredEthereumKeyRef> activeKeys = activeOrchidHops
        .map((h) {
          return h.keyRef;
        })
        .whereType<StoredEthereumKeyRef>()
        .toList();
    List<String> activeKeyUids = activeKeys.map((e) => e.keyUid).toList();
    log("account: activeKeyUuids = $activeKeyUids");
    return activeKeyUids;
  }

  @override
  String toString() {
    return 'OrchidHop{curator: $curator, keyRef: $keyRef, funder: $funder, version: $version, chainId: $chainId, resolvedSignerAddress: $resolvedSignerAddress}';
  }
}
