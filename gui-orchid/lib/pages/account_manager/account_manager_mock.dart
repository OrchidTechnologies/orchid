import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/vpn/preferences/user_preferences_mock.dart';
import '../../orchid/account/account_view_model.dart';

class AccountManagerMock {
// The Account Manager page view model.
  static List<AccountViewModel> accountViewModel = [
    _mockAccountViewModel(AccountMock.account1xdai),
    _mockAccountViewModel(AccountMock.account1bnb),
    _mockAccountViewModel(AccountMock.account1avalanche),
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
        active: UserPreferencesMock.mockCircuit.activeOrchidAccounts
            .contains(account),
      );
    } catch (err) {
      log("Error building mock account: $err");
      throw err;
    }
  }
}
