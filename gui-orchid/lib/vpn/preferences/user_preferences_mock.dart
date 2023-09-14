import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/vpn/model/circuit.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';

class UserPreferencesMock {
  static Circuit mockCircuit = Circuit([
    MockOrchidHop(AccountMock.account1polygon),
    MockOrchidHop(AccountMock.account1optimism),
    MockOrchidHop(AccountMock.account1xdai),
  ]);
}

class MockOrchidHop extends OrchidHop {
  MockAccount mockAccount;

  @override
  Account get account {
    return mockAccount;
  }

  MockOrchidHop(this.mockAccount) : super.fromAccount(mockAccount);
}
