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

  TabController _tabController;
  Widget _pageTitle = _logo;
  List<Widget> _pageActions = [];
  var _trafficButtonController = ClearTrafficActionButtonController();

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Orchid',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        home: new Scaffold(
          appBar: AppBar(
            title: _pageTitle,
            actions: _pageActions,
          ),
          body: TabBarView(
            controller: _tabController,

            children: [
              QuickConnectPage(),
              TrafficView(clearTrafficController: _trafficButtonController),
              CircuitPage(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: new TabBar(
              indicatorColor: Colors.transparent,
              controller: _tabController,
              tabs: [
                Tab(
                  text: "VPN",
                  icon: Image.asset("assets/images/swapVert.png",
                      color: _tabController.index == 0
                          ? Colors.white
                          : Colors.white60,
                      height: 24),
                ),
                Tab(
                  text: "Traffic",
                  icon: Image.asset("assets/images/rerouteAlt.png",
                      color: _tabController.index == 1
                          ? Colors.white
                          : Colors.white60,
                      height: 27),
                ),
                Tab(
                  text: "Circuit",
                  icon: Image.asset("assets/images/rerouteAlt.png",
                      color: _tabController.index == 2
                          ? Colors.white
                          : Colors.white60,
                      height: 27),
                )
              ],
            ),
          ),
          backgroundColor: Colors.deepPurple,
          drawer: SideDrawer(),
        ),
        routes: AppRoutes.routes);
  }

  void _handleTabSelection() {
    var titles = [_logo, Text("Traffic"), Text("Circuit")];
    setState(() {
      _pageTitle = titles[_tabController.index];
      _pageActions = _tabController.index == 1
          ? [ClearTrafficActionButton(controller: _trafficButtonController)]
          : [];
    });
  }
}
