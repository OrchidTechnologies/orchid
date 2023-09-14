import 'package:flutter_web3/flutter_web3.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';

/// This API implements the read-only eth calls shared by the dapp and the app,
/// overridding them to use the web3 context instead of default provider calls.
/// @see the OrchidEthereumV1 factory.
/// Note: This feels redundant but seems necessary?
class OrchidEthereumV1Web3Impl implements OrchidEthereumV1 {
  final OrchidWeb3Context _context;
  final Contract _lotteryContract;

  OrchidEthereumV1Web3Impl(this._context)
      : this._lotteryContract = Contract(
            OrchidContractV1.lotteryContractAddressV1,
            OrchidContractV1.abi,
            _context.web3);

  Future<Token> getGasPrice(Chain chain, {bool refresh = false}) async {
    if (chain != _context.chain) {
      throw Exception(
          "web3impl: asked to poll chain ${chain.chainId} with web3 provider: $_context");
    }
    // log('OrchidEthereumV1Web3Impl: get gas price');
    TokenType tokenType = chain.nativeCurrency;
    return tokenType.fromInt(await _context.web3.getGasPrice());
  }

  // Note: We currently only fetch uniswap prices from chains on main net.
  /*
  Future<double> getUniswapPrice(
      String poolAddress, int token0Decimals, int token1Decimals) async {
    var contract = new Contract(poolAddress, UniswapV3Contract.abi, provider);
    var result = await contract.call('slot0', []);
    // Q64.96 fixed-point number
    final sqrtPriceX96 = BigInt.parse(result[0].toString());
    return pow(sqrtPriceX96.toDouble(), 2) *
        pow(10, token0Decimals) /
        pow(10, token1Decimals) /
        pow(2, 192); // 96 * 2 bits
  }
   */

  Future<LotteryPot> getLotteryPot(
      {required Chain chain, required EthereumAddress funder, required EthereumAddress signer}) async {
    if (chain != _context.chain) {
      throw Exception(
          "web3impl: asked to poll chain ${chain.chainId} with web3 provider: $_context");
    }
    logDetail('OrchidEthereumV1Web3Impl: get lottery pot');
    // "function read(IERC20 token, address funder, address signer) external view returns (uint256, uint256)",
    // struct Account {
    //         uint256 escrow_amount_;
    //         uint256 unlock_warned_;
    //     }
    var result = await _lotteryContract.call('read', [
      EthereumAddress.zero.toString(prefix: false),
      _context.walletAddress!.toString(prefix: false),
      signer.toString(prefix: false),
    ]);
    var escrowAmount = BigInt.parse(result[0].toString());
    var unlockWarned = BigInt.parse(result[1].toString());

    TokenType tokenType = chain.nativeCurrency;
    Token escrow = tokenType.fromInt(escrowAmount >> 128);
    BigInt maskLow128 = (BigInt.one << 128) - BigInt.one;
    Token amount = tokenType.fromInt(escrowAmount & maskLow128);
    BigInt unlock = unlockWarned >> 128;
    Token warned = tokenType.fromInt(unlockWarned & maskLow128);

    return LotteryPot(
        balance: amount, deposit: escrow, unlock: unlock, warned: warned);
  }

  // Note: This method requires signer key to produce orchid accounts that
  // Note: are capable of signing.  If we need this in the web3 context we should
  // Note: provide another version that accepts the signer address and produces
  // Note: tracked accounts by address.
  Future<List<Account>> discoverAccounts(
      {required Chain chain, required StoredEthereumKey signer}) async {
    throw Exception('Account Discovery in web3 context unimplemented');
  }
}
