import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';

/// Mock account data for testing and screenshot generation
class AccountMock {
  static const mockAccounts =
      bool.fromEnvironment('mock_accounts', defaultValue: false);

  static final key1 =
      StoredEthereumKey(uid: 'key1', imported: true, private: BigInt.from(42));
  static final key2 =
      StoredEthereumKey(uid: 'key2', imported: true, private: BigInt.from(43));
  static final key3 =
      StoredEthereumKey(uid: 'key3', imported: true, private: BigInt.from(44));

  static final funder1 =
      EthereumAddress.from('0x42cc0d06ca2052ef93b5b7adfec2af7690731110');
  static final funder2 =
      EthereumAddress.from('0x69570d06ca2052ef93b5b7adfec2af7690731111');

  static List<StoredEthereumKey> mockKeys = [
    key1,
    key2,
    key3,
  ];

  static final account0eth = MockAccount(
    signerKey: key1,
    version: 1,
    chain: Chains.Ethereum,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.ETH.fromDouble(0.94),
      deposit: Tokens.ETH.fromDouble(0.50),
      warned: Tokens.ETH.fromDouble(0.25),
      mockMarketConditions: MockMarketConditions(efficiency: 0.94),
    ),
  );

  static final account1xdai = MockAccount(
    signerKey: key1,
    version: 1,
    chain: Chains.Gnosis,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.XDAI.fromDouble(0.94),
      deposit: Tokens.XDAI.fromDouble(0.50),
      mockMarketConditions: MockMarketConditions(efficiency: 0.94),
    ),
  );
  static final account1xdaiLocked = account1xdai;

  static final account1xdaiUnlocking = MockAccount(
    signerKey: key1,
    version: 1,
    chain: Chains.Gnosis,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.XDAI.fromDouble(0.94),
      deposit: Tokens.XDAI.fromDouble(0.50),
      mockMarketConditions: MockMarketConditions(efficiency: 0.94),
      warned: Tokens.XDAI.fromDouble(0.5),
      unlock: BigInt.from(
          DateTime.now().add(Duration(hours: 12)).millisecondsSinceEpoch /
              1000.0),
    ),
  );

  static final account1xdaiUnlocked = MockAccount(
    signerKey: key1,
    version: 1,
    chain: Chains.Gnosis,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.XDAI.fromDouble(0.94),
      deposit: Tokens.XDAI.fromDouble(0.50),
      mockMarketConditions: MockMarketConditions(efficiency: 0.94),
      warned: Tokens.XDAI.fromDouble(0.5),
      unlock: BigInt.from(
          DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch /
              1000.0),
    ),
  );

  static final account1xdaiPartUnlocked = MockAccount(
    signerKey: key1,
    version: 1,
    chain: Chains.Gnosis,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.XDAI.fromDouble(0.94),
      deposit: Tokens.XDAI.fromDouble(1.00),
      mockMarketConditions: MockMarketConditions(efficiency: 0.94),
      warned: Tokens.XDAI.fromDouble(0.5),
      unlock: BigInt.from(
          DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch /
              1000.0),
    ),
  );

  static final account1polygon = MockAccount(
    signerKey: key2,
    version: 1,
    chain: Chains.Polygon,
    funder: funder2,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.MATIC.fromDouble(4.00),
      deposit: Tokens.MATIC.fromDouble(2.00),
      mockMarketConditions: MockMarketConditions(efficiency: 0.98),
    ),
  );

  static final account1bnb = MockAccount(
    signerKey: key3,
    version: 1,
    chain: Chains.BinanceSmartChain,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.BNB.fromDouble(0.02),
      deposit: Tokens.BNB.fromDouble(0.01),
      mockMarketConditions: MockMarketConditions(efficiency: 0.78),
    ),
  );

  static final account1avalanche = MockAccount(
    signerKey: key2,
    version: 1,
    chain: Chains.Avalanche,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.AVAX.fromDouble(0.42),
      deposit: Tokens.AVAX.fromDouble(0.21),
      mockMarketConditions: MockMarketConditions(efficiency: 0.75),
    ),
  );

  static final account1optimism = MockAccount(
    signerKey: key3,
    version: 1,
    chain: Chains.Optimism,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.OETH.fromDouble(0.01),
      deposit: Tokens.OETH.fromDouble(0.01),
      mockMarketConditions: MockMarketConditions(efficiency: 0.95),
    ),
  );

  static final mockAccountDetail1 = MockAccountDetail(
    account: account1xdai,
    lotteryPot: account1xdai.mockLotteryPot,
    marketConditions: account1xdai.mockLotteryPot.mockMarketConditions,
  );
}

// A mock account has a mock lottery pot with mock market conditions.
// These mocks are recognized by the respective APIs without going to the network.
class MockAccount extends Account {
  final MockLotteryPot mockLotteryPot;

  @override
  StoredEthereumKey signerKey;

  MockAccount({
    required this.signerKey,
    EthereumAddress? resolvedSignerAddress,
    int version = 0,
    required Chain chain,
    required EthereumAddress funder,
    required this.mockLotteryPot,
  }) : super.base(
          signerKeyUid: signerKey.uid,
          resolvedSignerAddress: resolvedSignerAddress,
          version: version,
          chainId: chain.chainId,
          funder: funder,
        );
}

class MockLotteryPot extends LotteryPot {
  final MockMarketConditions mockMarketConditions;

  MockLotteryPot({
    required Token deposit,
    required Token balance,
    unlock,
    warned,
    required this.mockMarketConditions,
  }) : super(
          deposit: deposit,
          balance: balance,
          unlock: unlock ?? BigInt.zero,
          warned: warned ?? balance.type.zero,
        );
}

class MockAccountDetail extends AccountDetail {
  @override
  final Account account;

  @override
  final LotteryPot lotteryPot;

  @override
  final MarketConditions marketConditions;

  @override
  final bool showMarketStatsAlert;

  @override
  final List<OrchidUpdateTransactionV0>? transactions;

  @override
  EthereumAddress get signerAddress {
    return account.signerAddress;
  }

  MockAccountDetail({
    required this.account,
    required this.lotteryPot,
    required this.marketConditions,
    this.showMarketStatsAlert = false,
    this.transactions,
  });

  MockAccountDetail.fromMock(
    MockAccount account,
  ) : this(
          account: account,
          lotteryPot: account.mockLotteryPot,
          marketConditions: account.mockLotteryPot.mockMarketConditions,
        );
}

class MockMarketConditions extends MarketConditions {
  MockMarketConditions({
    required double efficiency,
  }) : super(Tokens.OXT.zero, Tokens.OXT.zero, efficiency, false);
}
