import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';

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

  TitledPage({@required this.title, @required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          title: Text(this.title),
          titleSpacing: 0,
          backgroundColor: Colors.deepPurple,
          elevation: 0.0),
      body: Container(
        child: child,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.grey_7, AppColors.grey_6])),
      ),
      // Workaround for: https://github.com/flutter/flutter/issues/23926
      resizeToAvoidBottomInset: false,
    );
  }
}
