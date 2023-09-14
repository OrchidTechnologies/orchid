import 'package:orchid/vpn/model/circuit_hop.dart';

class OpenVPNHop extends CircuitHop {
  final String userName;
  final String userPassword;
  final String ovpnConfig;

  OpenVPNHop(
      {required this.userName,
      required this.userPassword,
      required this.ovpnConfig})
      : super(HopProtocol.OpenVPN);

  OpenVPNHop.fromJson(Map<String, dynamic> json)
      : this.userName = json['username'],
        this.userPassword = json['password'],
        this.ovpnConfig = json['ovpnfile'],
        super(HopProtocol.OpenVPN);

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'username': userName,
        'password': userPassword,
        'ovpnfile': ovpnConfig
      };
}
