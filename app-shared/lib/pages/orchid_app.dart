import 'package:flutter/material.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/pages/common/side_drawer.dart';
import 'package:orchid/pages/common/wrapped_switch.dart';
import 'package:orchid/pages/connect/connect_page.dart';
import 'circuit/circuit_page.dart';
import 'monitoring/traffic_view.dart';

// TODO: Remove if this remains unused
// Single page app layout
class OrchidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Note: keep the MaterialApp above the widget to set the navigation context.
    return MaterialApp(
        title: 'Orchid',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        routes: AppRoutes.routes,
        home: CircuitPage());
  }
}

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
      QuickConnectPage(key: PageStorageKey("1")),
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

  void updateStatusTab() async {
    _showStatusTab = await UserPreferences().getShowStatusTab();
    _handleTabSelection(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Orchid',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: _pageTitle,
            actions: _pageActions,
          ),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomNav(),
          backgroundColor: Colors.deepPurple,
          drawer: SideDrawer(),
        ),
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes);
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
                  title: Text("Status"),
                  icon: Image.asset(
                    "assets/images/statusV2.png",
                    height: 27,
                    color: _selectedIndex == 0 ? Colors.white : Colors.white60,
                  )),
            BottomNavigationBarItem(
                title: Text("Hops"),
                icon: Image.asset(
                  "assets/images/rerouteAlt.png",
                  height: 27,
                  color: _selectedIndex == (_showStatusTab ? 1 : 0)
                      ? Colors.white
                      : Colors.white60,
                )),
            BottomNavigationBarItem(
                title: Text("Traffic"),
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

  void _handleTabSelection(int index) {
    var titles = [
      _logo,
      _logo,
      Text("Traffic"),
    ];
    setState(() {
      _selectedIndex = index;
      _pageTitle = titles[_showStatusTab ? index : index + 1];
      if (index == (_showStatusTab ? 1 : 0)) {
        _pageActions = [WrappedSwitch(controller: _vpnSwitchController)];
      } else if (index == (_showStatusTab ? 2 : 1)) {
        _pageActions = [ClearTrafficActionButton(controller: _trafficButtonController)];
      } else {
        _pageActions = [];
      }
    });
  }
}
