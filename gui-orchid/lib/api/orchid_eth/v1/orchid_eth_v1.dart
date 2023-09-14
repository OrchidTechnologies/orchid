import 'package:orchid/api/orchid_eth/token_type.dart';
import '../chains.dart';
import '../orchid_account.dart';
import '../orchid_lottery.dart';
import '../../orchid_crypto.dart';
import 'orchid_eth_v1_rpc.dart';

/// This API describes the read-only eth calls shared by the dapp and the app
/// and allows them to be overridden in the web3 context.
abstract class OrchidEthereumV1 {
  static OrchidEthereumV1? _shared;

  // This method is used by the dapp to set a web3 provider implementation
  static setWeb3Provider(OrchidEthereumV1? impl) {
    _shared = impl;
  }

  /// Return the default eth api provider.  This will be the direct
  /// json rpc endpoint for the chain unless overridden by providing a web3
  /// context provider.
  factory OrchidEthereumV1() {
    if (_shared == null) {
      _shared = OrchidEthereumV1JsonRpcImpl.init();
    }
    return _shared!;
  }

  // This call is generic and can be used with any contract version.
  Future<Token> getGasPrice(Chain chain, {bool refresh = false});

  // This call is generic and can be used with any contract version.
  // Note: We currently only fetch uniswap prices from chains on main net.
  // Future<double> getUniswapPrice(String poolAddress, int token0Decimals, int token1Decimals);

  Future<List<Account>> discoverAccounts(
      {required Chain chain, required StoredEthereumKey signer});

  Future<LotteryPot> getLotteryPot(
      {required Chain chain, required EthereumAddress funder, required EthereumAddress signer});
}
