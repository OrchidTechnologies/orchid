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
  moveLocation,
  pokeLocation,
}

/// Persistent transaction data
class DappTransaction {
  final String? transactionHash;
  final int chainId;
  final DappTransactionType? type;

  // An optional subtype for components of a composite transaction.
  // e.g. ERC20 transfer requiring an approval and a push.
  final String? subtype;

  // If this is part of a series of transactions, the index and total count.
  final int? series_index;
  final int? series_total;

  DappTransaction({
    this.transactionHash,
    required this.chainId,
    this.type,
    this.subtype,
    this.series_index = null,
    this.series_total = null,
  });

  DappTransaction.fromJson(Map<String, dynamic> json)
      : this.transactionHash = json['tx'],
        this.chainId = json['chainId'],
        // toTransactionType() handles nulls
        this.type = toTransactionType(json['type']),
        this.subtype = json['subtype'],
        this.series_index = json['series_index'],
        this.series_total = json['series_total'];

  Map<String, dynamic> toJson() => {
        'tx': transactionHash,
        'chainId': chainId,
        'type': (type ?? DappTransactionType.unknown).name,
        'subtype': subtype,
        'series_index': series_index,
        'series_total': series_total,
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
    String text = descriptionForType(context, type);
    if (subtype != null) {
      if (series_index != null && series_total != null) {
        text += " ($subtype, $series_index/$series_total)";
      } else {
        text += " ($subtype)";
      }
    }
    return text;
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
      case DappTransactionType.pullFunds:
        return "Pull Funds";
      case DappTransactionType.moveLocation:
        return "Move Location";
      case DappTransactionType.pokeLocation:
        return "Poke Location";
      case DappTransactionType.unknown:
        return "...";
    }
  }

  @override
  String toString() {
    return 'DappTransaction{transactionHash: $transactionHash, chainId: $chainId, type: $type}';
  }
}
