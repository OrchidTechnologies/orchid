import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/orchid/orchid_desktop_dragscroll.dart';
import 'package:orchid/orchid/orchid_gradients.dart';

/*
  e.g.
  import 'package:flutter/material.dart';
  import 'package:orchid/util/test_app.dart';
  void main() {
    runApp(TestApp(content: _Test()));
  }
 */
class TestApp extends StatelessWidget {
  final Widget content;
  final double scale;

  const TestApp({
    Key key,
    @required this.content,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: OrchidLanguage.localizationsDelegates,
      supportedLocales: OrchidLanguage.supportedLocales,
      home: Material(
        child: Container(
          decoration:
              BoxDecoration(gradient: OrchidGradients.blackGradientBackground),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Transform.scale(scale: scale, child: content),
          ),
        ),
      ),
      scrollBehavior: OrchidDesktopDragScrollBehavior(),
    );
  }
}
