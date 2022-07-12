class DappTransaction {
  final String transactionHash;
  final int chainId;

  DappTransaction({this.transactionHash, this.chainId});

  DappTransaction.fromJson(Map<String, dynamic> json)
      : this.transactionHash = json['tx'],
        // this.chainId = int.parse(json['chainId']);
        this.chainId = json['chainId'];

  Map<String, dynamic> toJson() => {
        'tx': transactionHash,
        // 'chainId': chainId.toString(),
        'chainId': chainId,
      };

  static List<DappTransaction> fromList(List<dynamic> list) {
    return list.map((el) {
      return DappTransaction.fromJson(el);
    }).toList();
  }

  @override
  String toString() {
    return 'DappTransaction{transactionHash: $transactionHash, chainId: $chainId}';
  }
}
