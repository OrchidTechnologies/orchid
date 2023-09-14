import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/dapp/orchid/transaction_status_panel.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/builder/token_price_builder.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_identicon.dart';
import 'package:orchid/api/pricing/usd.dart';
import '../../api/orchid_eth/token_type.dart';

class DappWalletInfoPanel extends StatelessWidget {
  final OrchidWeb3Context? web3Context;

  DappWalletInfoPanel({
    Key? key,
    required this.web3Context,
  }) : super(key: key);

  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);

  @override
  Widget build(BuildContext context) {
    if (web3Context == null) {
      return Container();
    }
    return RoundedRect(
      backgroundColor: OrchidColors.new_purple,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final link = web3Context?.chain.explorerUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.s.connectedWithMetamask, style: _textStyle),
          ],
        ).height(26),
        _buildWalletAddressRow().top(16),
        DappUtil.buildExplorerLink(context, _textStyle, link,
                disabled: link == null)
            .top(8),
        _buildWalletBalances(context).top(12),
        // _buildDisconnectButton(context).top(24),
        pady(16)
      ],
    );
  }

  Widget _buildWalletAddressRow() {
    if (web3Context?.walletAddress == null) {
      return Container();
    }
    final text = web3Context!.walletAddress!.toString(elide: false);

    return TapToCopyText(
      text,
      padding: EdgeInsets.zero,
      style: OrchidText.title.copyWith(height: 1.7),
      displayWidget: Row(
        children: [
          SizedBox(
              width: 28,
              height: 28,
              child: OrchidIdenticon(address: web3Context!.walletAddress)),
          Text(
            web3Context!.walletAddress!.toString(elide: true),
            style: OrchidText.title,
            overflow: TextOverflow.visible,
          ).left(16).top(4),
          Spacer(),
          Icon(Icons.copy, size: 18, color: Colors.white),
        ],
      ),
    ).height(30);
  }

  Widget _buildWalletBalances(BuildContext context) {
    final textStyle = OrchidText.normal_16_025.copyWith(height: 2.0);
    final wallet = web3Context?.wallet;
    if (wallet?.balance == null) {
      return Container();
    }
    var showOxtBalance = wallet!.oxtBalance != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.s.balance, style: textStyle),
        _buildBalanceRow(context, wallet.balance!).top(12),
        if (showOxtBalance)
          _buildBalanceRow(context, wallet.oxtBalance!).top(12),
      ],
    );
  }

  Widget _buildBalanceRow(BuildContext context, Token balance) {
    final numberStyle = OrchidText.title.copyWith(fontSize: 22);
    final priceStyle = OrchidText.medium_14.newPurpleBright;
    final tokenType = balance.type;
    return TapToCopyText(
      balance.floatValue.toString(),
      style: OrchidText.title.copyWith(height: 1.8),
      padding: EdgeInsets.zero,
      displayWidget: Column(
        children: [
          // Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                balance.toFixedLocalized(
                  locale: context.locale,
                  minPrecision: 1,
                  maxPrecision: 5,
                  showPrecisionIndicator: true,
                ),
                style: numberStyle,
                textAlign: TextAlign.right,
              ),
              Row(
                children: [
                  SizedBox.square(dimension: 20, child: balance.type.icon)
                      .bottom(4),
                  Text(balance.type.symbol, style: numberStyle).left(12),
                ],
              ),
            ],
          ),
          // Localized price
          TokenPriceBuilder(
              tokenType: tokenType,
              builder: (USD? tokenPrice) {
                final usdText = ((tokenPrice ?? USD.zero) * balance.floatValue)
                    .formatCurrency(locale: context.locale);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usdText,
                      style: priceStyle,
                      textAlign: TextAlign.right,
                    ),
                    Text('USD', style: priceStyle),
                  ],
                );
              }),
        ],
      ),
    ).height(40);
  }
}
