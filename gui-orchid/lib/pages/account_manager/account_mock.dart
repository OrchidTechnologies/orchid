import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_market.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/orchid/account/account_detail_poller.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'account_view_model.dart';

/// Mock account data for testing and screenshot generation
class AccountMock {
  static const mockAccounts = bool.fromEnvironment('mock_accounts', defaultValue: false);

  static final key1 = StoredEthereumKey(
      uid: 'key1', imported: true, private: BigInt.from(42));
  static final key2 = StoredEthereumKey(
      uid: 'key2', imported: true, private: BigInt.from(43));
  static final key3 = StoredEthereumKey(
      uid: 'key3', imported: true, private: BigInt.from(44));

  static final funder1 = EthereumAddress.from('0x42cc0d06ca2052ef93b5b7adfec2af7690731110');
  static final funder2 = EthereumAddress.from('0x69570d06ca2052ef93b5b7adfec2af7690731111');

  static List<StoredEthereumKey> mockKeys = [
    key1,
    key2,
    key3,
  ];

  static final account1xdai = MockAccount(
    signerKey: key1,
    version: 1,
    chain: Chains.xDAI,
    funder: funder1,
    mockLotteryPot: MockLotteryPot(
      balance: Tokens.XDAI.fromDouble(0.94),
      deposit: Tokens.XDAI.fromDouble(0.50),
      mockMarketConditions: MockMarketConditions(efficiency: 0.94),
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

  static Circuit mockCircuit = Circuit([
    MockOrchidHop(account1polygon),
    MockOrchidHop(account1optimism),
    MockOrchidHop(account1xdai),
  ]);

  // The Account Manager page view model.
  static List<AccountViewModel> accountViewModel = [
    _mockAccountViewModel(account1xdai),
    _mockAccountViewModel(account1bnb),
    _mockAccountViewModel(account1avalanche),
  ];

  static AccountViewModel _mockAccountViewModel(MockAccount account) {
    try {
      return AccountViewModel(
        signerKey: account.signerKey,
        funder: account.funder,
        chain: account.chain,
        detail: MockAccountDetail(
          account: account,
          lotteryPot: account.mockLotteryPot,
          marketConditions: account.mockLotteryPot.mockMarketConditions,
        ),
        active: mockCircuit.activeOrchidAccounts.contains(account),
      );
    } catch (err) {
      log("Error building mock account: $err");
      throw err;
    }
  }
}

// A mock account has a mock lottery pot with mock market conditions.
// These mocks are recognized by the respective APIs without going to the network.
class MockAccount extends Account {
  final MockLotteryPot mockLotteryPot;

  @override
  StoredEthereumKey signerKey;

  MockAccount({
    @required this.signerKey,
    EthereumAddress resolvedSignerAddress,
    int version = 0,
    Chain chain,
    EthereumAddress funder,
    @required this.mockLotteryPot,
  }) : super.base(
          signerKeyUid: signerKey.uid,
          resolvedSignerAddress: resolvedSignerAddress,
          version: version,
          chainId: chain.chainId,
          funder: funder,
        );

/*
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Account &&
              runtimeType == other.runtimeType &&
              signerKeyUid == other.signerKeyUid &&
              version == other.version &&
              chainId == other.chainId &&
              funder == other.funder;

  @override
  int get hashCode =>
      signerKeyUid.hashCode ^
      version.hashCode ^
      chainId.hashCode ^
      funder.hashCode;
   */
}

class MockLotteryPot extends LotteryPot {
  final MockMarketConditions mockMarketConditions;

  MockLotteryPot({
    @required Token deposit,
    @required Token balance,
    unlock,
    warned,
    @required this.mockMarketConditions,
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
  final List<OrchidUpdateTransactionV0> transactions;

  MockAccountDetail({
    @required this.account,
    @required this.lotteryPot,
    @required this.marketConditions,
    this.showMarketStatsAlert,
    this.transactions,
  });
}

class MockMarketConditions extends MarketConditions {
  MockMarketConditions({
    @required double efficiency,
  }) : super(null, null, efficiency, false);
}

class MockOrchidHop extends OrchidHop {
  MockAccount mockAccount;

  @override
  Account get account {
    return mockAccount;
  }

  MockOrchidHop(this.mockAccount) : super.fromAccount(mockAccount);
}
