import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/common/token_price_builder.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_wallet_identicon.dart';
import '../api/orchid_eth/token_type.dart';
import '../util/units.dart';
import 'dapp_button.dart';

class DappWalletInfoPanel extends StatelessWidget {
  final OrchidWeb3Context web3Context;
  final VoidCallback onDisconnect;

  DappWalletInfoPanel({
    Key key,
    @required this.web3Context,
    @required this.onDisconnect,
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
    final link = web3Context?.chain?.explorerUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Connected with Metamask", style: _textStyle),
          ],
        ).height(26).top(12),
        _buildWalletAddressRow().top(16),
        buildExplorerLink(_textStyle, link).top(8),
        _buildWalletBalances(context).top(12),
        // _buildDisconnectButton(context).top(24),
        pady(16)
      ],
    ).padx(24);
  }

  static Widget buildExplorerLink(TextStyle textStyle, String link,
      {MainAxisAlignment alignment = MainAxisAlignment.start}) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Transform.rotate(
            angle: -3.14 / 4,
            child: Icon(Icons.arrow_forward, color: Colors.white)),
        Text("Block Explorer", style: textStyle).link(url: link).left(8),
      ],
    );
  }

  Widget _buildWalletAddressRow() {
    final text = web3Context.walletAddress.toString(elide: false);

    return TapToCopyText(
      text,
      padding: EdgeInsets.zero,
      style: OrchidText.title.copyWith(height: 1.7),
      displayWidget: Row(
        children: [
          SizedBox(
              width: 28,
              height: 28,
              child: OrchidWalletIdenticon(address: web3Context.walletAddress)),
          Text(
            web3Context.walletAddress.toString(elide: true),
            style: OrchidText.title,
            overflow: TextOverflow.visible,
          ).left(16).top(4),
          Spacer(),
          Icon(Icons.copy, size: 18, color: Colors.white),
        ],
      ),
    ).height(30);
  }

  Widget _buildDisconnectButton(BuildContext context) {
    return DappButton(
        text: context.s.disconnect.toUpperCase(),
        onPressed: () async {
          // Navigator.pop(context);
          onDisconnect();
        });
  }

  Widget _buildWalletBalances(BuildContext context) {
    final textStyle = OrchidText.normal_16_025.copyWith(height: 2.0);
    final wallet = web3Context?.wallet;
    if (wallet == null) {
      return Container();
    }
    var showOxtBalance = wallet.oxtBalance != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.s.balance, style: textStyle),
        _buildBalanceRow(context, wallet.balance).top(12),
        if (showOxtBalance)
          _buildBalanceRow(context, wallet.oxtBalance).top(12),
      ],
    );
  }

  Widget _buildBalanceRow(BuildContext context, Token balance) {
    final numberStyle = OrchidText.title.copyWith(fontSize: 22);
    final priceStyle = OrchidText.medium_14.newPurpleBright;
    final tokenType = balance?.type ?? Tokens.TOK;
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
                balance.toFixedLocalized(locale: context.locale),
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
              builder: (USD tokenPrice) {
                final usdText = ((tokenPrice ?? USD.zero) * balance.floatValue)
                        .formatCurrency(locale: context.locale) ??
                    '';
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
