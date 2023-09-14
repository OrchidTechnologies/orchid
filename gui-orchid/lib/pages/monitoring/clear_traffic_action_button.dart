import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/vpn/monitoring/analysis_db.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/util/localization.dart';

class ClearTrafficActionButtonController {
  // Tri-state enabled status
  ValueNotifier<bool?> enabled = ValueNotifier(null);
}

class ClearTrafficActionButton extends StatelessWidget {
  final ClearTrafficActionButtonController controller;

  const ClearTrafficActionButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
        valueListenable: controller.enabled,
        builder: (context, enabledOrNull, child) {
          bool enabled = enabledOrNull ?? false;
          bool visible = enabledOrNull != null;
          return Visibility(
            visible: visible,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.3,
              child: TextButton(
                child: SvgPicture.asset(OrchidAssetSvg.delete_icon_path,
                    width: 24, height: 24),
                onPressed: enabled
                    ? () {
                        _confirmDelete(context);
                      }
                    : null,
              ),
            ),
          );
        });
  }

  void _confirmDelete(BuildContext context) {
    AppDialogs.showConfirmationDialog(
        context: context,
        title: context.s.clearAllAnalysisData,
        bodyText:
            context.s.thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData,
        cancelText: context.s.cancelButtonTitle.toUpperCase(),
        actionText: context.s.clearAll,
        commitAction: () async {
          await AnalysisDb().clear();
        });
  }
}
