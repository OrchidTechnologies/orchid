import 'package:flutter/material.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/pages/common/side_drawer.dart';
import 'package:orchid/pages/connect/connect_page.dart';
import 'circuit/circuit_page.dart';
import 'monitoring/traffic_view.dart';

class OrchidApp extends StatefulWidget {
  @override
  _OrchidAppState createState() => _OrchidAppState();
}

class _OrchidAppState extends State<OrchidApp> with TickerProviderStateMixin {
  static var _logo = Image.asset("assets/images/name_logo.png",
      color: Colors.white, height: 24);

  Widget _pageTitle = _logo;
  List<Widget> _pageActions = [];
  var _trafficButtonController = ClearTrafficActionButtonController();

  int _selectedIndex = 0;
  List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      QuickConnectPage(key: PageStorageKey("1")),
      TrafficView(
          key: PageStorageKey("2"),
          clearTrafficController: _trafficButtonController),
      CircuitPage(key: PageStorageKey("3")),
    ];
  }

  final PageStorageBucket bucket = PageStorageBucket();

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
        routes: AppRoutes.routes);
  }

  PageStorage _buildBody() {
    return PageStorage(child: _tabs.elementAt(_selectedIndex), bucket: bucket);
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
            BottomNavigationBarItem(
                title: Text("Status"),
                icon: Image.asset(
                  "assets/images/statusV2.png",
                  height: 27,
                  color: _selectedIndex == 0 ? Colors.white : Colors.white60,
                )),
            BottomNavigationBarItem(
                title: Text("Traffic"),
                icon: Image.asset(
                  "assets/images/swapVert.png",
                  height: 24,
                  color: _selectedIndex == 1 ? Colors.white : Colors.white60,
                )),
            BottomNavigationBarItem(
                title: Text("Hops"),
                icon: Image.asset(
                  "assets/images/rerouteAlt.png",
                  height: 27,
                  color: _selectedIndex == 2 ? Colors.white : Colors.white60,
                )),
          ]),
    );
  }

  void _handleTabSelection(int index) {
    var titles = [_logo, Text("Traffic"), Text("Circuit")];
    setState(() {
      _selectedIndex = index;
      _pageTitle = titles[index];
      _pageActions = index == 1
          ? [ClearTrafficActionButton(controller: _trafficButtonController)]
          : [];
    });
  }
}
