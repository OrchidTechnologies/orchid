import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'token_type.dart';

class Chains {
  // ignore: non_constant_identifier_names
  static const int ETH_CHAINID = 1;

  static final _defaultEthereumProviderUrl = 'htt' +
      'ps://et' +
      'h-main' +
      'ne' +
      't.alc' +
      'hemya' +
      'pi.i' +
      'o/v' +
      '2/VwJMm1VlCgpmjULmKeaVAt3Ik4XVwxO0';

  static String get defaultEthereumProviderUrl {
    return _overriddenEthereumProviderUrl;
  }

  // Get the provider URL allowing override in the advanced config
  static String get _overriddenEthereumProviderUrl {
    var jsConfig = OrchidUserConfig().getUserConfigJS();
    // Note: This var is also used by the tunnel for the eth provider.
    return jsConfig.evalStringDefault('rpc', _defaultEthereumProviderUrl);
  }

  // ignore: non_constant_identifier_names
  static Chain Ethereum = Chain(
    chainId: ETH_CHAINID,
    name: "Ethereum",
    nativeCurrency: TokenTypes.ETH,
    providerUrl: defaultEthereumProviderUrl,
    icon: SvgPicture.asset('assets/svg/orchid_icon.svg'),
  );

  // ignore: non_constant_identifier_names
  static const int XDAI_CHAINID = 100;
  static Chain xDAI = Chain(
    chainId: XDAI_CHAINID,
    name: "xDAI",
    nativeCurrency: TokenTypes.XDAI,
    // providerUrl: 'https://dai.poa.network',
    providerUrl: 'https://rpc.xdaichain.com/',
    icon: SvgPicture.asset('assets/svg/logo-xdai2.svg'),
  );

  // TODO: Embed the chain.info db here as we do in the dapp.
  // Get the chain for chainId
  static Chain chainFor(int chainId) {
    switch (chainId) {
      case ETH_CHAINID:
        return Ethereum;
      case XDAI_CHAINID:
        return xDAI;
    }
    throw Exception("no chain for chainId: $chainId");
  }
}

class Chain {
  final int chainId;
  final String name;
  final TokenType nativeCurrency;
  final String providerUrl;

  // Optional icon svg
  final SvgPicture icon;

  const Chain({
    @required this.chainId,
    @required this.name,
    @required this.nativeCurrency,
    @required this.providerUrl,
    this.icon,
  });

  Future<Token> getGasPrice({bool refresh = false}) {
    return OrchidEthereumV1().getGasPrice(this, refresh: refresh);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chain &&
          runtimeType == other.runtimeType &&
          chainId == other.chainId;

  @override
  int get hashCode => chainId.hashCode;

  @override
  String toString() {
    return 'Chain{chainId: $chainId, name: $name}';
  }
}
