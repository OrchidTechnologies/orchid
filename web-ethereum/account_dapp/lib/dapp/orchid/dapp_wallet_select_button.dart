import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid/orchid.dart';
import '../../orchid/menu/orchid_popup_menu_button.dart';

class DappWalletSelectButton extends StatefulWidget {
  final double width;
  final TextStyle selectedTextStyle;
  final TextStyle unselectedTextStyle;
  final Color backgroundColor;
  final VoidCallback connectMetamask;
  final VoidCallback connectWalletConnect;
  final VoidCallback disconnect;
  final bool enabled;
  final bool connected;

  DappWalletSelectButton({
    Key? key,
    required this.width,
    required this.backgroundColor,
    required this.selectedTextStyle,
    required this.unselectedTextStyle,
    required this.connectMetamask,
    required this.connectWalletConnect,
    this.enabled = true,
    required this.disconnect,
    this.connected = false,
  }) : super(key: key);

  @override
  State<DappWalletSelectButton> createState() => _DappWalletSelectButtonState();
}

class _DappWalletSelectButtonState extends State<DappWalletSelectButton> {
  final _width = 275.0;
  final _height = 50.0;
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    return OrchidPopupMenuButton<String>(
      enabled: widget.enabled,
      disabledAppearance: !widget.enabled,
      width: widget.width,
      height: 40,
      selected: _buttonSelected,
      backgroundColor: _buttonSelected ? null : widget.backgroundColor,
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
          // header item
          _buildHeaderItem(),
          PopupMenuDivider(height: 1.0),
          if (!widget.connected)
            _buildWalletItem(
              title: "MetaMask",
              icon: OrchidAsset.svg.metamask,
              onPressed: widget.connectMetamask,
              topPad: 12,
            ),
          if (!widget.connected)
            _buildWalletItem(
              title: "WalletConnect",
              icon: OrchidAsset.svg.walletconnect,
              onPressed: widget.connectWalletConnect,
              topPad: 8,
              bottomPad: 12,
            ),

          if (widget.connected)
            PopupMenuItem<String>(
              height: _height,
              onTap: widget.disconnect,
              child: _buildDisconnectButton(),
            ),
        ];
      },
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            s.connect.toUpperCase(),
            style: _buttonSelected
                ? widget.selectedTextStyle
                : widget.unselectedTextStyle,
          )),
    );
  }

  PopupMenuItem<String> _buildHeaderItem() {
    return PopupMenuItem<String>(
      enabled: false,
      child: SizedBox(
        width: _width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Connect a wallet",
              style: widget.unselectedTextStyle.white.withHeight(2.0),
            ).left(4),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildWalletItem({
    required Widget icon,
    required String title,
    required VoidCallback onPressed,
    double topPad = 0,
    double bottomPad = 0,
  }) {
    return PopupMenuItem<String>(
      height: _height,
      onTap: onPressed,
      child: SizedBox(
        height: _height,
        child: RoundedRect(
          radius: 12,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Row(
            children: [
              icon.left(12).right(10),
              Text(title, style: _textStyle),
            ],
          ),
        ),
      ).padx(4).top(topPad).bottom(bottomPad),
    );
  }

  Widget _buildDisconnectButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.power_settings_new_rounded, color: Colors.white),
        Text(
          "Disconnect",
          style: _textStyle,
        ).left(8),
      ],
    );
  }
}
