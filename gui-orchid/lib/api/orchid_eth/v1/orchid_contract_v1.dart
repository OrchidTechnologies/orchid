import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config.dart';

class OrchidContractV1 {
  // Lottery contract address (all chains, singleton deployment).
  // TODO: This is the (in-progress) xDai V1 contract address
  // static var _lotteryContractAddressV1 = '0xDBbB66055F403aD3cb605f2406aC6529525E0000';
  static var _lotteryContractAddressV1 =
      '0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b';

  static Future<String> get lotteryContractAddressV1 async {
    return (await OrchidVPNConfig.getUserConfigJS())
        .evalStringDefault("lottery", _lotteryContractAddressV1);
  }

  static String createEventHashV1 =
      // '0x96b5b9b8a7193304150caccf9b80d150675fa3d6af57761d8d8ef1d6f9a1a909';
      '0x923f1fa2c44c3aec741bc0bb74cfdb2d73d61ea532799cda54b2941d89ab9fc6';

  static String readMethodHash = '5185c7d7';

  static int gasCostToRedeemTicket = 100000;
  static int lotteryMoveMaxGas = 175000;
  static int createAccountMaxGas = lotteryMoveMaxGas;
}
