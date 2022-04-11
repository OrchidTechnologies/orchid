import 'package:orchid/orchid.dart';
import 'package:orchid/common/token_price_builder.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/common/tap_copy_text.dart';
import 'package:orchid/orchid/orchid_wallet_identicon.dart';
import '../api/orchid_eth/token_type.dart';
import '../util/units.dart';
import 'dapp_button.dart';
import 'dapp_header_popup_button.dart';

class DappWalletButton extends StatefulWidget {
  final OrchidWeb3Context web3Context;
  final VoidCallback onDisconnect;
  final bool showBalance;

  DappWalletButton({
    Key key,
    @required this.web3Context,
    @required this.onDisconnect,
    @required this.showBalance,
  }) : super(key: key);

  @override
  State<DappWalletButton> createState() => _DappWalletButtonState();
}

class _DappWalletButtonState extends State<DappWalletButton> {
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    return DappHeaderPopupMenuButton<String>(
      showBorder: true,
      selected: _buttonSelected,
      onSelected: (String item) {
        setState(() {
          _buttonSelected = false;
        });
      },
      onCanceled: () {
        setState(() {
          _buttonSelected = false;
        });
      },
      itemBuilder: (itemBuilderContext) {
        setState(() {
          _buttonSelected = true;
        });
        return [
          PopupMenuItem<String>(
              padding: EdgeInsets.zero,
              value: "none",
              // height: _height,
              child: _buildExpandedContent(context)),
        ];
      },
      child: _buildTitle(context),
      // icon: OrchidAsset.svg.settings_gear,
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.web3Context == null) {
      return Row(
        children: [
          Text("...").title,
        ],
      );
    }
    final balanceText = widget.web3Context.wallet?.balance
        ?.formatCurrency(locale: context.locale);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child:
              OrchidWalletIdenticon(address: widget.web3Context.walletAddress),
        ).left(16),
        Text(
          widget.web3Context.walletAddress.toString(elide: true),
          softWrap: false,
          overflow: TextOverflow.fade,
          style: _textStyle,
        ).left(16),
        if (widget.showBalance)
          SizedBox(
            width: 20,
            height: 20,
            child: widget.web3Context.wallet?.balance?.type?.icon ?? padx(20),
          ).left(16),
        if (widget.showBalance)
          SizedBox(
            width: 108,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: balanceText != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        balanceText,
                        style: _textStyle,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                    )
                  : Container(),
            ),
          ).left(8),
        padx(16),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final link = widget.web3Context.chain.explorerUrl;
    return SizedBox(
      width: 290,
      child: Column(
        children: [
          Row(
            children: [
              Text("Connected with Metamask", style: _textStyle),
            ],
          ).top(0),
          _buildWalletAddressRow().top(16),
          _buildWalletBalances(context).top(16),
          Row(
            children: [
              Transform.rotate(
                  angle: -3.14 / 4,
                  child: Icon(Icons.arrow_forward, color: Colors.white)),
              Text("Block Explorer", style: _textStyle)
                  .link(url: link)
                  .left(16),
            ],
          ).top(16),
          _buildDisconnectButton(context).top(24),
          pady(16)
        ],
      ).padx(24),
    );
  }

  Row _buildWalletAddressRow() {
    return Row(
      children: [
        SizedBox(
            width: 28,
            height: 28,
            child: OrchidWalletIdenticon(
                address: widget.web3Context.walletAddress)),
        TapToCopyText(
          widget.web3Context.walletAddress.toString(elide: false),
          displayText: widget.web3Context.walletAddress.toString(elide: true),
          style: OrchidText.title,
          padding: EdgeInsets.zero,
          overflow: TextOverflow.visible,
        ).left(16).top(4),
      ],
    );
  }

  Widget _buildDisconnectButton(BuildContext context) {
    return SizedBox(
      width: 240,
      child: DappButton(
          text: context.s.disconnect.toUpperCase(),
          onPressed: () async {
            Navigator.pop(context);
            widget.onDisconnect();
          }),
    );
  }

  Widget _buildWalletBalances(BuildContext context) {
    final wallet = widget.web3Context?.wallet;
    if (wallet == null) {
      return Container();
    }
    var showOxtBalance = wallet.oxtBalance != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Balance", style: _textStyle),
        _buildBalanceRow(context, wallet.balance).top(12),
        if (showOxtBalance)
          _buildBalanceRow(context, wallet.oxtBalance).top(12),
      ],
    );
  }

  Widget _buildBalanceRow(BuildContext context, Token balance) {
    final numberStyle = OrchidText.title.copyWith(fontSize: 22);
    final priceStyle = OrchidText.medium_14.newPurpleBright;
    return Column(
      children: [
        // Balance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectableText(
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
            tokenType: balance.type,
            builder: (USD tokenPrice) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectableText(
                    tokenPrice?.formatCurrency(locale: context.locale) ?? '',
                    style: priceStyle,
                    textAlign: TextAlign.right,
                  ),
                  Text('USD', style: priceStyle),
                ],
              );
            }),
      ],
    );
  }
}
