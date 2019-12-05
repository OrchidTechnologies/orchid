import 'circuit_hop.dart';

class OpenVPNHop extends CircuitHop {
  final String userName;
  final String userPassword;
  final String ovpnConfig;

  OpenVPNHop({this.userName, this.userPassword, this.ovpnConfig})
      : super(Protocol.OpenVPN);

  factory OpenVPNHop.fromJson(Map<String, dynamic> json) {
    return OpenVPNHop(
        userName: json['username'],
        userPassword: json['password'],
        ovpnConfig: json['ovpnfile']);
  }

  Map<String, dynamic> toJson() => {
        'protocol': CircuitHop.protocolToString(protocol),
        'username': userName,
        'password': userPassword,
        'ovpnfile': ovpnConfig
      };
}
