import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/pages/side_drawer.dart';
import 'connect/connect_page.dart';

// Provide the MaterialApp wrapper and localization context.
class OrchidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Orchid',
      // No localization
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: OrchidPlatform.languageOverride == null
          ? S.supportedLocales
          : [
              Locale.fromSubtags(
                  languageCode: OrchidPlatform.languageOverrideCode,
                  countryCode: OrchidPlatform.languageOverrideCountry)
            ],
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: OrchidAppNoTabs(),
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
    );
  }
}

class OrchidAppNoTabs extends StatefulWidget {
  @override
  _OrchidAppNoTabsState createState() => _OrchidAppNoTabsState();
}

class _OrchidAppNoTabsState extends State<OrchidAppNoTabs> {
  ValueNotifier<Color> _backgroundColor = ValueNotifier(Colors.white);
  ValueNotifier<Color> _iconColor = ValueNotifier(Color(0xFF3A3149));

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {}

  // If the hop is empty initialize it to defaults now.
  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    OrchidPlatform.staticLocale = locale;
    log("locale = $locale");
    var preferredSize = Size.fromHeight(kToolbarHeight);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: preferredSize,
        child: AnimatedBuilder(
            animation: Listenable.merge([_backgroundColor, _iconColor]),
            builder: (context, snapshot) {
              return AppBar(
                backgroundColor: _backgroundColor.value,
                elevation: 0,
                iconTheme: IconThemeData(color: _iconColor.value),
                brightness: Brightness.light,
                // status bar
                actions: [_buildTrafficButton()],
              );
            }),
      ),
      body: _body(),
      backgroundColor: Colors.white,
      drawer: SideDrawer(),
    );
  }

  Widget _buildTrafficButton() {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.traffic);
      },
      child: Image.asset(
        'assets/images/swapVert.png',
        width: 24,
        height: 24,
      ),
    );
  }

  Widget _body() {
    return ConnectPage(
      appBarColor: _backgroundColor,
      iconColor: _iconColor,
    );
  }
}

/*
/// A bottom navigation tabbed layout of the app
class OrchidAppTabbed extends StatefulWidget {
  static var showStatusTabPref = ChangeNotifier();

  @override
  _OrchidAppTabbedState createState() => _OrchidAppTabbedState();
}

class _OrchidAppTabbedState extends State<OrchidAppTabbed>
    with TickerProviderStateMixin {
  static var _logo = Image.asset("assets/images/name_logo.png",
      color: Colors.white, height: 24);

  Widget _pageTitle = _logo;
  List<Widget> _pageActions = [];
  var _trafficButtonController = ClearTrafficActionButtonController();
  var _vpnSwitchController = WrappedSwitchController();

  final PageStorageBucket bucket = PageStorageBucket();
  int _selectedIndex = 0;
  List<Widget> _tabs;
  bool _showStatusTab = false;

  @override
  void initState() {
    super.initState();

    _tabs = [
      LegacyConnectPage(key: PageStorageKey("1")),
      CircuitPage(
          key: PageStorageKey("2"), switchController: _vpnSwitchController),
      TrafficView(
          key: PageStorageKey("3"),
          clearTrafficController: _trafficButtonController),
    ];

    initStateAsync();
  }

  void initStateAsync() async {
    updateStatusTab();
    OrchidAppTabbed.showStatusTabPref.addListener(() {
      updateStatusTab();
    });
  }

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    log("locale = $locale");
    return Scaffold(
      appBar: AppBar(
        title: _pageTitle,
        actions: _pageActions,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      backgroundColor: Colors.deepPurple,
      drawer: SideDrawer(),
    );
  }

  PageStorage _buildBody() {
    return PageStorage(
        child: _tabs
            .elementAt(_showStatusTab ? _selectedIndex : _selectedIndex + 1),
        bucket: bucket);
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.deepPurple,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          currentIndex: _selectedIndex,
          onTap: _handleTabSelection,
          items: <BottomNavigationBarItem>[
            if (_showStatusTab)
              BottomNavigationBarItem(
                  title: Text(s.status),
                  icon: Image.asset(
                    "assets/images/statusV2.png",
                    height: 27,
                    color: _selectedIndex == 0 ? Colors.white : Colors.white60,
                  )),
            BottomNavigationBarItem(
                title: Text(s.hops),
                icon: Image.asset(
                  "assets/images/rerouteAlt.png",
                  height: 27,
                  color: _selectedIndex == (_showStatusTab ? 1 : 0)
                      ? Colors.white
                      : Colors.white60,
                )),
            BottomNavigationBarItem(
                title: Text(s.traffic),
                icon: Image.asset(
                  "assets/images/swapVert.png",
                  height: 24,
                  color: _selectedIndex == (_showStatusTab ? 2 : 1)
                      ? Colors.white
                      : Colors.white60,
                )),
          ]),
    );
  }

  void updateStatusTab() async {
    _showStatusTab = await UserPreferences().getShowStatusTab();
    _handleTabSelection(_selectedIndex);
  }

  void _handleTabSelection(int index) {
    var titles = [
      _logo,
      _logo,
      Text(s.traffic),
    ];
    setState(() {
      _selectedIndex = index;
      _pageTitle = titles[_showStatusTab ? index : index + 1];
      if (index == (_showStatusTab ? 1 : 0)) {
        _pageActions = [WrappedSwitch(controller: _vpnSwitchController)];
      } else if (index == (_showStatusTab ? 2 : 1)) {
        _pageActions = [
          ClearTrafficActionButton(controller: _trafficButtonController)
        ];
      } else {
        _pageActions = [];
      }
    });
  }

  S get s {
    return S.of(context);
  }
}
 */
