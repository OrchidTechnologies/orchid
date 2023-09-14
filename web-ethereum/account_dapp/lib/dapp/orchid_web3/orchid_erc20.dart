import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_log.dart';
import 'orchid_web3_context.dart';

class OrchidERC20 {
  final OrchidWeb3Context context;
  final TokenType tokenType;
  final Contract _contract;

  OrchidERC20({
    required this.context,
    required this.tokenType,
  }) : this._contract = Contract(
            tokenType.erc20Address.toString(), _erc20Abi, context.web3);

  /// Get the OXT balance for this wallet
  Future<Token> getERC20Balance(EthereumAddress address) async {
    var balance = await _contract.call('balanceOf', [address.toString()]);
    return tokenType.fromIntString(balance.toString());
  }

  /// Get the OXT allowance for this wallet
  Future<Token> getERC20Allowance(
      {required EthereumAddress owner, required EthereumAddress spender}) async {
    // allowance(address owner, address spender) external view returns (uint256)",
    var allowance = await _contract.call('allowance', [
      owner.toString(),
      spender.toString(),
    ]);
    return tokenType.fromIntString(allowance.toString());
  }

  /// Approve for transfer the total amount from the user to the specified lottery contract.
  /// If the total exceeds the wallet balance the amount value is automatically reduced.
  Future<String /*TransactionId*/ > approveERC20({
    required EthereumAddress owner,
    required EthereumAddress spender,
    required Token amount,
  }) async {
    var walletBalance = await getERC20Balance(owner);

    // Don't attempt to add more than the wallet balance.
    // This mitigates the potential for rounding errors in calculated amounts.
    amount = Token.min(amount, walletBalance);

    log('XXX: do approve: ${[spender.toString(), amount.intValue.toString()]}');

    // approve(address spender, uint256 amount) external returns (bool)
    var contract = _contract.connect(context.web3.getSigner());
    TransactionResponse tx = await contract.send(
      'approve',
      [
        spender.toString(),
        amount.intValue.toString(),
      ],
      TransactionOverride(
          gasLimit: BigInt.from(OrchidContractV0.gasLimitApprove)),
    );
    log('XXX: approveHash = ${tx.hash}');
    return tx.hash;
  }

  static List<String> _erc20Abi = [
    'function balanceOf(address account) external view returns (uint256)',
    'function transfer(address recipient, uint256 amount) external returns (bool)',
    'function allowance(address owner, address spender) external view returns (uint256)',
    'function approve(address spender, uint256 amount) external returns (bool)',
    'function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)',
  ];
}
