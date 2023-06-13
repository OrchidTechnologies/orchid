
class UniswapV3Contract {

  static final String slot0Hash = '3850c7bd';

  // This is the pool abi.  See the respective tokens for pool contract addresses.
  static List<String> abi = [
    'function slot0() external view returns (uint160, int24)',
  ];
}
