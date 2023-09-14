import 'package:orchid/orchid/orchid.dart';

enum DappTransactionType {
  unknown,
  addFunds,
  withdrawFunds,
  pullFunds,
  fundContractDeployer,
  deploySingletonFactory,
  deployContract,
  lockDeposit,
  unlockDeposit,
  moveFunds,
  accountChanges,
}

/// Persistent transaction data
class DappTransaction {
  final String? transactionHash;
  final int chainId;
  final DappTransactionType? type;

  DappTransaction({
    this.transactionHash,
    required this.chainId,
    this.type,
  });

  DappTransaction.fromJson(Map<String, dynamic> json)
      : this.transactionHash = json['tx'],
        this.chainId = json['chainId'],
        this.type = toTransactionType(json['type']); // handles null

  Map<String, dynamic> toJson() => {
        'tx': transactionHash,
        'chainId': chainId,
        'type': (type ?? DappTransactionType.unknown).name,
      };

  static List<DappTransaction> fromList(List<dynamic> list) {
    return list.map((el) {
      return DappTransaction.fromJson(el);
    }).toList();
  }

  // map legacy transactions to the unknown type
  static DappTransactionType toTransactionType(String s) {
    try {
      return DappTransactionType.values.byName(s);
    } catch (e) {
      log("XXX: dapp tx enum not found: $s");
      return DappTransactionType.unknown;
    }
  }

  String description(BuildContext context) {
    return descriptionForType(context, type);
  }

  static String descriptionForType(
      BuildContext context, DappTransactionType? type) {
    final s = context.s;
    switch (type ?? DappTransactionType.unknown) {
      case DappTransactionType.addFunds:
        return context.s.addFunds2;
      case DappTransactionType.withdrawFunds:
        return context.s.withdrawFunds2;
      case DappTransactionType.fundContractDeployer:
        return s.fundContractDeployer;
      case DappTransactionType.deploySingletonFactory:
        return s.deploySingletonFactory;
      case DappTransactionType.deployContract:
        return s.deployContract;
      case DappTransactionType.lockDeposit:
        return s.lockDeposit2;
      case DappTransactionType.unlockDeposit:
        return s.unlockDeposit2;
      case DappTransactionType.moveFunds:
        return s.moveFunds2;
      case DappTransactionType.accountChanges:
        return s.accountChanges;
      case DappTransactionType.unknown:
      default:
        return "...";
    }
  }

  @override
  String toString() {
    return 'DappTransaction{transactionHash: $transactionHash, chainId: $chainId, type: $type}';
  }
}
