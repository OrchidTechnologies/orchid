import 'package:flutter/material.dart';
import 'package:orchid/pages/app_gradients.dart';

/// A second level page reached through navigation.
/// These pages have a title with a back button.
class TitledPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool lightTheme;
  final List<Widget> actions;
  final VoidCallback backAction;
  final bool cancellable;
  final BoxDecoration decoration;

  TitledPage({
    @required this.title,
    @required this.child,
    this.lightTheme = true,
    this.actions = const [],
    this.backAction,
    this.cancellable = false,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          leading: _buildBackButton(context),
          actions: actions,
          title: Text(
            this.title,
            style: TextStyle(color: _foregroundColor()),
          ),
          titleSpacing: 0,
          backgroundColor: _backgroundColor(),
          brightness: Brightness.light, // status bar
          elevation: 0.0),
      body: Container(
        child: child,
        decoration: decoration ?? BoxDecoration(gradient: AppGradients.basicGradient),
      ),

      // Note: Setting this to false is a workaround for:
      // https://github.com/flutter/flutter/issues/23926
      // however that breaks the automated keyboard accommodation.
      resizeToAvoidBottomInset: true,
    );
  }

  Color _foregroundColor() {
    return lightTheme ? Colors.black : Colors.white;
  }

  Color _backgroundColor() {
    return lightTheme ? Colors.white : Colors.deepPurple;
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
      backAction();
    } else {
      Navigator.pop(context);
    }
  }
}
