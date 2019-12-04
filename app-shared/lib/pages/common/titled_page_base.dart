import 'package:flutter/material.dart';
import 'package:orchid/pages/app_gradients.dart';

/// A base class for stateless second level pages reached through navigation.
/// These pages have a title with a back button.
class TitledPageBase extends StatelessWidget {
  final String title;

  TitledPageBase({this.title});

  @override
  Widget build(BuildContext context) {
    return TitledPage(title: title, child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    throw AssertionError("override this method");
  }
}

/// A second level page reached through navigation.
/// These pages have a title with a back button.
class TitledPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool lightTheme;
  final List<Widget> actions;
  final VoidCallback backAction;
  final bool cancellable;

  TitledPage({
    @required this.title,
    @required this.child,
    this.lightTheme = false,
    this.actions = const [],
    this.backAction,
    this.cancellable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: _buildBackButton(context),
          actions: actions,
          title: Text(
            this.title,
            style: TextStyle(color: _foregroundColor()),
          ),
          titleSpacing: 0,
          backgroundColor: _backgroundColor(),
          elevation: 0.0),
      body: Container(
        child: child,
        decoration: BoxDecoration(gradient: AppGradients.basicGradient),
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
      icon: Icon(cancellable ? Icons.close : Icons.arrow_back,
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
