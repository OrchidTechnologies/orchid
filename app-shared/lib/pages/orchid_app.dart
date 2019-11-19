import 'package:flutter/material.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/pages/common/side_drawer.dart';
import 'package:orchid/pages/connect/connect_page.dart';
import 'package:orchid/pages/monitoring/monitoring_page.dart';
import 'package:orchid/pages/keys/keys_page.dart';

import 'circuit/circuit_page.dart';

class OrchidApp extends StatefulWidget {
  @override
  _OrchidAppState createState() => _OrchidAppState();
}

class _OrchidAppState extends State<OrchidApp> with TickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {});
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
            title: Image.asset("assets/images/name_logo.png",
                color: Colors.white, height: 24),
            //actions: <Widget>[_buildSwitch()],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [QuickConnectPage(), MonitoringPage(), CircuitPage(), KeysPage()],
          ),
          bottomNavigationBar: SafeArea(
            child: new TabBar(
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
                ),
                Tab(
                  text: "Keys",
                  icon: Image.asset("assets/images/balanceOpt.png",
                      color: _tabController.index == 3
                          ? Colors.white
                          : Colors.white60,
                      height: 27),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.deepPurple,
          drawer: SideDrawer(),
        ),
        routes: AppRoutes.routes);
  }
}
