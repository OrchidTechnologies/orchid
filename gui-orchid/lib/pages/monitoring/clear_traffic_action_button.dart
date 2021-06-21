import 'package:flutter/material.dart';
import 'package:orchid/api/monitoring/analysis_db.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_dialogs.dart';

import '../../common/app_colors.dart';
import '../../common/app_text.dart';

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
              child: FlatButton(
                color: AppColors.white,
                child: Text(s.clear,
                    style: AppText.actionButtonStyle
                        .copyWith(color: AppColors.purple_3)),
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
        title: s.deleteAllData + "?",
        bodyText: s.thisWillDeleteRecorded,
        cancelText: s.cancelButtonTitle,
        actionText: s.okButtonTitle,
        commitAction: () async {
          await AnalysisDb().clear();
        });
  }
}
