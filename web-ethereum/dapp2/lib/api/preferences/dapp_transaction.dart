import '../../orchid.dart';

class DappTransaction {
  final String transactionHash;
  final int chainId;
  final String description;

  DappTransaction({
    @required this.transactionHash,
    @required this.chainId,
    @required this.description,
  });

  DappTransaction.fromJson(Map<String, dynamic> json)
      : this.transactionHash = json['tx'],
        this.chainId = json['chainId'],
        this.description = json['description'];

  Map<String, dynamic> toJson() => {
        'tx': transactionHash,
        'chainId': chainId,
        'description': description,
      };

  static List<DappTransaction> fromList(List<dynamic> list) {
    return list.map((el) {
      return DappTransaction.fromJson(el);
    }).toList();
  }

  @override
  String toString() {
    return 'DappTransaction{transactionHash: $transactionHash, chainId: $chainId, description: $description}';
  }
}
