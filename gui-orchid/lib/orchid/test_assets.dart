import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/test_app.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatefulWidget {
  const _Test({Key? key}) : super(key: key);

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
      OrchidAssetSvgChain.unknown_chain_path,
      // OrchidAssetSvgChain.avalanche_chain_path,
      OrchidAssetSvgChain.arbitrum_chain_path,
      OrchidAssetSvgChain.binance_smart_chain_path,
      // OrchidAssetSvgChain.ethereum_chain_path,
      // OrchidAssetSvgChain.fantom_chain_path,
      OrchidAssetSvgChain.gnossis_chain_path,
      OrchidAssetSvgChain.near_aurora_chain_path,
      OrchidAssetSvgChain.neon_evm_chain_path,
      OrchidAssetSvgChain.optimism_chain_path,
      // OrchidAssetSvgChain.polygon_chain_path,
      OrchidAssetSvgChain.ronin_chain_path,
      OrchidAssetSvgChain.rsk_chain_path,
      // OrchidAssetSvgChain.telos_chain_path,
    ];
    return _buildRows(chains);
  }

  Widget _buildTokens() {
    var tokens = [
      OrchidAssetSvgToken.unknown_token_path,
      OrchidAssetSvgToken.avalanche_avax_token_path,
      OrchidAssetSvgToken.binance_coin_bnb_token_path,
      OrchidAssetSvgToken.bitcoin_btc_token_path,
      OrchidAssetSvgToken.celo_token_path,
      OrchidAssetSvgToken.clover_clv_token_path,
      OrchidAssetSvgToken.ethereum_classic_etc_token_path,
      OrchidAssetSvgToken.ethereum_eth_token_path,
      OrchidAssetSvgToken.fantom_ftm_token_path,
      OrchidAssetSvgToken.fuse_token_path,
      OrchidAssetSvgToken.huobi_ht_token_path,
      OrchidAssetSvgToken.klay_token_path,
      OrchidAssetSvgToken.matic_token_path,
      OrchidAssetSvgToken.moonbeam_glmr_token_path,
      OrchidAssetSvgToken.moonriver_movr_token_path,
      OrchidAssetSvgToken.okt_token_path,
      OrchidAssetSvgToken.orchid_oxt_token_path,
      OrchidAssetSvgToken.poa_token_path,
      OrchidAssetSvgToken.telos_tlos_token_path,
      OrchidAssetSvgToken.xdai_token_path,
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
