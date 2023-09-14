import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_text.dart';

/// A second level page reached through navigation.
/// These pages have a title with a back button.
class TitledPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool lightTheme;
  final List<Widget> actions;
  final VoidCallback? backAction;
  final bool cancellable;

  // final BoxDecoration? decoration;
  final bool constrainWidth;

  TitledPage({
    this.title = '',
    required this.child,
    this.lightTheme = false,
    this.actions = const [],
    this.backAction,
    this.cancellable = false,
    // this.decoration,
    this.constrainWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: OrchidGradients.blackGradientBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: _buildBackButton(context),
          actions: actions,
          title: Text(this.title,
              textAlign: TextAlign.center,
              style: OrchidText.title
                  .copyWith(color: _foregroundColor(), height: 2.0)),
          titleSpacing: 0,
          backgroundColor: Colors.transparent,
          // brightness: Brightness.dark,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          // status bar
          elevation: 0.0,
        ),
        body: constrainWidth ? AppSize.constrainMaxSizeDefaults(child) : child,

        // Note: Setting this to false is a workaround for:
        // https://github.com/flutter/flutter/issues/23926
        // however that breaks the automated keyboard accommodation.
        resizeToAvoidBottomInset: true,
      ),
    );
  }

  Color _foregroundColor() {
    return lightTheme ? Colors.black : Colors.white;
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Icon(cancellable ? Icons.close : Icons.arrow_back_ios,
          color: _foregroundColor()),
      onPressed: () {
        _performBackAction(context);
      },
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }

  void _performBackAction(BuildContext context) async {
    if (backAction != null) {
      backAction!();
    } else {
      Navigator.pop(context);
    }
  }
}
