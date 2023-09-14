import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid/orchid_desktop_dragscroll.dart';
import 'package:orchid/orchid/orchid_gradients.dart';

/*
  e.g.
  // Note: This redundant import of material is required in the main dart file.
  import 'package:flutter/material.dart';
  import 'package:orchid/util/test_app.dart';
  void main() {
    TestApp.run(scale: 1.0, content: _Test());
  }
 */
class TestApp extends StatelessWidget {
  final Widget content;
  final double scale;

  TestApp({
    Key? key,
    required this.content,
    this.scale = 1.0,
  }) : super(key: key);

  static void run({double? scale, required Widget content}) async {
    WidgetsFlutterBinding.ensureInitialized();
    await UserPreferences.init();
    runApp(TestApp(scale: scale ?? 1.0, content: content));
  }

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
