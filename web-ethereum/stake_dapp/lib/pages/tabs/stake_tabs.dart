import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/orchid/orchid.dart';
import 'add_stake_panel.dart';
import 'pull_stake_panel.dart';
import 'withdraw_stake_panel.dart';

/// The tabs for interacting with the V0 contract.
class StakeTabs extends StatefulWidget {
  final OrchidWeb3Context? web3Context;
  final EthereumAddress? stakee;
  final Token? currentStake;
  final USD? price;

  const StakeTabs({
    Key? key,
    required this.web3Context,
    required this.stakee,
    required this.currentStake,
    required this.price,
  }) : super(key: key);

  @override
  State<StakeTabs> createState() => _StakeTabsState();
}

class _StakeTabsState extends State<StakeTabs> {
  @override
  void initState() {
    super.initState();
  }

  bool get _enabled {
    return widget.web3Context != null && widget.stakee != null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      width: 700,
      child: DefaultTabController(
        initialIndex: 0,
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, 50),
            child: TabBar(
              indicatorColor: OrchidColors.tappable,
              tabs: [
                Tab(child: FittedBox(child: Text(s.add1).button)),
                Tab(child: FittedBox(child: Text("Pull").button)),
                Tab(child: FittedBox(child: Text(s.withdraw).button)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildAddStakePanel(),
              _buildPullStakePanel(),
              _buildWithdrawStakePanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddStakePanel() {
    return AddStakePanel(
      enabled: _enabled,
      web3context: widget.web3Context,
      stakee: widget.stakee,
      currentStake: widget.currentStake,
      price: widget.price,
    );
  }

  Widget _buildPullStakePanel() {
    return PullStakePanel(
      enabled: _enabled,
      web3context: widget.web3Context,
      stakee: widget.stakee,
      currentStake: widget.currentStake,
      price: widget.price,
    );
  }

  Widget _buildWithdrawStakePanel() {
    return WithdrawStakePanel(
      enabled: _enabled,
      web3context: widget.web3Context,
      stakee: widget.stakee,
      currentStake: widget.currentStake,
      price: widget.price,
    );
  }
}
