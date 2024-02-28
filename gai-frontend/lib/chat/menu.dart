import 'package:orchid/orchid/menu/expanding_popup_menu_item.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_item_utils.dart';
import 'package:orchid/orchid/menu/submenu_popup_menu_item.dart';


class OrchataMenuButton extends StatefulWidget {
  final int? contractVersionSelected;
  final void Function(int version)? selectContractVersion;
  final Set<int>? contractVersionsAvailable;
  final VoidCallback? deployContract;

  OrchataMenuButton({
    Key? key,
    this.contractVersionSelected,
    required this.selectContractVersion,
    required this.contractVersionsAvailable,
    this.deployContract,
  }) : super(key: key);

  @override
  State<OrchataMenuButton> createState() => _OrchataMenuButtonState();
}

class _OrchataMenuButtonState extends State<OrchataMenuButton> {
  final _width = 273.0;
  final _height = 50.0;
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    final buildCommit =
        const String.fromEnvironment('build_commit', defaultValue: '...');
    final githubUrl =
        'https://github.com/OrchidTechnologies/orchid/tree/$buildCommit/web-ethereum/dapp2';
    return OrchidPopupMenuButton<dynamic>(
      width: 40,
      height: 40,
      selected: _buttonSelected,
      onSelected: (item) {
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
//        final available = widget.contractVersionsAvailable;
//        final selected = widget.contractVersionSelected;
//        final showContractVersions =
//            (available ?? {}).isNotEmpty && selected != null;

        setState(() {
          _buttonSelected = true;
        });

        return [
/*
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildIdenticonsPref,
          ),
          PopupMenuDivider(height: 1.0),
          SubmenuPopopMenuItemBuilder<String>(
            builder: _buildLanguagePref,
          ),
          if (showContractVersions) ...[
            PopupMenuDivider(height: 1.0),
            SubmenuPopopMenuItemBuilder<String>(
              builder: _buildContractVerionsPref,
            ),
          ],

          // View contract links
          if (widget.contractVersionSelected != null)
            ..._viewContractLinkMenuItems(
                context: context,
                available: widget.contractVersionsAvailable!,
                selected: widget.contractVersionSelected!,
                textStyle: _textStyle),

          PopupMenuDivider(height: 1.0),
*/
          PopupMenuItem<String>(
            onTap: () {
              Future.delayed(millis(0), () async {
                _openLogsPage(context);
              });
            },
            height: _height,
            child: SizedBox(
              width: _width,
              child: Text(s.viewLogs, style: _textStyle),
            ),
          ),
        ],
      },
    ),
  },
}

