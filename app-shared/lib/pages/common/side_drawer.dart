import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';

class SideDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.dark_purple,
            gradient: new LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.drawer_gradient_start,
                  AppColors.drawer_gradient_end
                ])),
        child: buildContent(context),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        // The menu items
        Column(
          children: <Widget>[
            // top logo
            DrawerHeader(
              child: Image(image: AssetImage('assets/images/logo.png')),
            ),

            divider(),

            tile(
              title: "Connect",
              imageName:
                  'assets/images/connect.png',
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
            ),

            divider(),

            tile(
              title: "Settings",
              imageName: 'assets/images/settings.png',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),

            divider(),

            tile(
              title: "Help",
              imageName: 'assets/images/help.png',
              onPressed: () {
                Navigator.pushNamed(context, '/help');
              },
            ),

            divider(),

            tile(
              title: "Feedback",
              imageName: 'assets/images/feedback.png',
              onPressed: () {
                Navigator.pushNamed(context, '/feedback');
              },
            ),

            divider(),
          ],
        )
      ],
    );
  }

  Widget divider() {
    return Divider(
      color: Colors.white.withAlpha((0.12 * 255).toInt()),
      height: 1.0,
    );
  }

  Widget tile({String title, String imageName, VoidCallback onPressed}) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 20),
        leading: Image(
            height: 32,
            width: 32,
            fit: BoxFit.fill,
            alignment: Alignment.center,
            color: Colors.white,
            image: AssetImage(imageName)),
        title: Text(title,
            textAlign: TextAlign.left,
            style: const TextStyle(
                color: const Color(0xffffffff),
                fontWeight: FontWeight.w500,
                fontFamily: "Roboto",
                fontStyle: FontStyle.normal,
                fontSize: 16.0)),
        onTap: onPressed);
  }
}
