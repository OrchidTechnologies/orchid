import 'package:flutter/services.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_desktop_dragscroll.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/pages/side_drawer.dart';
import 'connect/connect_page.dart';

// Provide the MaterialApp wrapper and localization context.
class OrchidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Orchid',
      localizationsDelegates: OrchidLanguage.localizationsDelegates,
      supportedLocales: OrchidLanguage.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: OrchidAppNoTabs(),
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      scrollBehavior: OrchidDesktopDragScrollBehavior(),
    );
  }
}

class OrchidAppNoTabs extends StatefulWidget {
  @override
  _OrchidAppNoTabsState createState() => _OrchidAppNoTabsState();
}

class _OrchidAppNoTabsState extends State<OrchidAppNoTabs> {
  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    OrchidLanguage.staticLocale = locale;
    var preferredSize = Size.fromHeight(kToolbarHeight);
    return Container(
      decoration:
          BoxDecoration(gradient: OrchidGradients.blackGradientBackground),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
            preferredSize: preferredSize,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              // brightness: Brightness.dark,
              systemOverlayStyle:
                  SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
              // status bar
              actions: [_buildTrafficButton()],
            )),
        body: _body(),
        backgroundColor: Colors.transparent,
        drawer: SideDrawer(),
      ),
    );
  }

  Widget _buildTrafficButton() {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.traffic);
      },
      child: OrchidAsset.svg.traffic,
    );
  }

  // Produce the main app body, which at large sizes is constrained and centered at top.
  Widget _body() {
    return AppSize.constrainMaxSizeDefaults(ConnectPage());
  }
}
