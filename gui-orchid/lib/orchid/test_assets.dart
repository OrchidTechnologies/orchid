import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/util/test_app.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatefulWidget {
  const _Test({Key key}) : super(key: key);

  @override
  __TestState createState() => __TestState();
}

class __TestState extends State<_Test> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildChains().pad(32),
        _buildTokens().pad(32),
      ],
    );
  }

  Widget _buildChains() {
    var chains = [
      OrchidAssetChain.unknown_chain,
      OrchidAssetChain.avalanche_chain,
      OrchidAssetChain.arbitrum_chain,
      OrchidAssetChain.binance_smart_chain,
      OrchidAssetChain.ethereum_chain,
      OrchidAssetChain.fantom_chain,
      OrchidAssetChain.gnossis_chain,
      OrchidAssetChain.near_aurora_chain,
      OrchidAssetChain.neon_evm_chain,
      OrchidAssetChain.optimism_chain,
      OrchidAssetChain.polygon_chain,
      OrchidAssetChain.ronin_chain,
      OrchidAssetChain.rsk_chain,
      OrchidAssetChain.telos_chain,
    ];
    return _buildRows(chains);
  }

  Widget _buildTokens() {
    var tokens = [
      OrchidAssetToken.unknown_token,
      OrchidAssetToken.avalanche_avax_token,
      OrchidAssetToken.binance_coin_bnb_token,
      OrchidAssetToken.bitcoin_btc_token,
      OrchidAssetToken.celo_token,
      OrchidAssetToken.clover_clv_token,
      OrchidAssetToken.ethereum_classic_etc_token,
      OrchidAssetToken.ethereum_eth_token,
      OrchidAssetToken.fantom_ftm_token,
      OrchidAssetToken.fuse_token,
      OrchidAssetToken.huobi_ht_token,
      OrchidAssetToken.klay_token,
      OrchidAssetToken.matic_token,
      OrchidAssetToken.moonbeam_glmr_token,
      OrchidAssetToken.moonriver_movr_token,
      OrchidAssetToken.okt_token,
      OrchidAssetToken.orchid_oxt_token,
      OrchidAssetToken.poa_token,
      OrchidAssetToken.telos_tlos_token,
      OrchidAssetToken.xdai_token,
    ];
    return _buildRows(tokens);
  }

  Widget _buildRows(List<String> values) {
    var icons = values
        .map(
          (e) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 350,
                  child: Text(
                    e,
                    style: TextStyle(color: Colors.white),
                  )),
              Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.white)),
                width: 40,
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(e),
                ),
              ),
            ],
          ),
        )
        .toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: icons,
    );
  }
}
