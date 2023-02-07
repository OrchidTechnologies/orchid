// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/monitoring/analysis_db.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid_asset.dart';

class ClearTrafficActionButtonController {
  // Tri-state enabled status
  ValueNotifier<bool> enabled = ValueNotifier(null);
}

class ClearTrafficActionButton extends StatelessWidget {
  final ClearTrafficActionButtonController controller;

  const ClearTrafficActionButton({this.controller});

  @override
  Widget build(BuildContext context) {
    S s = S.of(context);
    return ValueListenableBuilder<bool>(
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
    S s = S.of(context);
    AppDialogs.showConfirmationDialog(
        context: context,
        title: s.clearAllAnalysisData,
        bodyText:
            s.thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData,
        cancelText: s.cancelButtonTitle.toUpperCase(),
        actionText: s.clearAll,
        commitAction: () async {
          await AnalysisDb().clear();
        });
  }
}
