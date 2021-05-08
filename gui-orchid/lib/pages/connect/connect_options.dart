import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:orchid/common/options_bar.dart';

class ConnectOptionsBar extends StatelessWidget {
  const ConnectOptionsBar({
    Key key,
    @required Animation<Color> iconColor,
    @required AnimationController connectAnimController,
  })  : _iconColor = iconColor,
        _connectAnimController = connectAnimController,
        super(key: key);

  final Animation<Color> _iconColor;
  final AnimationController _connectAnimController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        children: <Widget>[
          // The optional notification banner
          AnimatedSwitcher(
            //child: NotificationBannerFactory.current() ?? Container(),
            child: Container(),
            transitionBuilder: (widget, anim) {
              var tween =
                  Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero)
                      .animate(anim);
              return SlideTransition(position: tween, child: widget);
            },
            duration: Duration(milliseconds: 200),
          ),
          // The options bar. (Animated builder allows the color transition).
          AnimatedBuilder(
            builder: (context, child) {
              // https://stackoverflow.com/questions/45424621/inkwell-not-showing-ripple-effect
              //Material
              return OptionsBar(
                color: _iconColor.value,
                menuPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                morePressed: () {},
              );
            },
            animation: _connectAnimController,
          ),
        ],
      ),
    );
  }
}
