import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:rxdart/rxdart.dart';

/// The primiary connect and reroute buttons.
class ConnectButton extends StatefulWidget {
  final Observable<OrchidConnectionState> connectionStatus;
  final Observable<bool> enabledStatus;
  final VoidCallback onConnectButtonPressed;
  final VoidCallback onRerouteButtonPressed;

  // Feature flag for reroute button.
  final bool enableRerouteButton = false;

  ConnectButton({
    @required this.connectionStatus,
    @required this.enabledStatus,
    @required this.onConnectButtonPressed,
    @required this.onRerouteButtonPressed,
  });

  @override
  ConnectButtonState createState() => ConnectButtonState();
}

class ConnectButtonState extends State<ConnectButton>
    with TickerProviderStateMixin {
  OrchidConnectionState connectionState = OrchidConnectionState.Invalid;
  bool enabled = true;

  AnimationController _pulseAnimationController;
  AnimationController _teeterAnimationController;

  List<StreamSubscription> _rxSubscriptions = List();

  @override
  void initState() {
    super.initState();

    _rxSubscriptions
        .add(widget.connectionStatus.listen((OrchidConnectionState state) {
      setState(() {
        this.connectionState = state;
      });
    }));

    _rxSubscriptions.add(widget.enabledStatus.listen((bool state) {
      setState(() {
        this.enabled = state;
      });
    }));

    _pulseAnimationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 4000));
    _pulseAnimationController.repeat();

    _teeterAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _teeterAnimationController.repeat(reverse: true);
  }

  bool _showRerouteButton() {
    if (!widget.enableRerouteButton || !enabled) {
      return false;
    }
    switch (connectionState) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Disconnecting:
        return false;
      case OrchidConnectionState.Connected:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    String image;
    switch (connectionState) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Disconnecting:
        image = 'connect_button_enabled.png';
        break;
      case OrchidConnectionState.Connected:
        image = 'connect_button_connected.png';
    }

    var imageButtonName =
        'assets/images/' + (enabled ? image : 'connect_button_disabled');
    var buttonImage = Image.asset(imageButtonName);
    var rerouteImage = Image.asset('assets/images/reroute_button.png');
    double buttonWidth = 146;

    // Drop shadow when needed
    var buttonShadowDecoration = enabled
        ? BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(
                blurRadius: 10.0,
                color: AppColors.dark_indego_45,
                offset: Offset(3.0, 4.0))
          ])
        : null;

    double screenWidth = MediaQuery.of(context).size.width;

    Animation<double> _pulseSize = _pulseAnimationController
        .drive(Tween(begin: buttonWidth, end: buttonWidth * 2.3));

    Animation<double> _offsetPulseSize = _pulseAnimationController
        .drive(OffsetPhaseAnimation(0.5))
        .drive(Tween(begin: buttonWidth, end: buttonWidth * 2.3));

    Animation<double> _pulseAlpha =
        _pulseAnimationController.drive(Tween(begin: 1.0, end: 0.0));

    Animation<double> _offsetPulseAlpha = _pulseAnimationController
        .drive(OffsetPhaseAnimation(0.5))
        .drive(Tween(begin: 1.0, end: 0.0));

    Animation<double> _teeterAnim = _teeterAnimationController
        .drive(CurveTween(curve: Curves.easeInOutSine));

    int teeterBaseAlpha = (0.4 * 255).round();

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Visibility(
          visible: connectionState == OrchidConnectionState.Connected,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              buildPing(sizeAnim: _pulseSize, alphaAnim: _pulseAlpha),
              buildPing(
                  sizeAnim: _offsetPulseSize, alphaAnim: _offsetPulseAlpha),
            ],
          ),
        ),

        Visibility(
          visible: connectionState == OrchidConnectionState.Connecting,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              buildTeeter(0.5, teeterBaseAlpha, screenWidth, _teeterAnim),
              buildTeeter(1.0, teeterBaseAlpha, screenWidth, _teeterAnim),
            ],
          ),
        ),

        // connect button
        Container(
          decoration: buttonShadowDecoration,
          child: FlatButton(
              //splashColor: Colors.transparent,
              //highlightColor: Colors.transparent,
              child: buttonImage,
              onPressed: enabled ? widget.onConnectButtonPressed : null,
              shape: CircleBorder()),
        ),

        // re-route button
        Container(
          //color: Colors.orange.withAlpha(100),
          width: 215, height: 215,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Visibility(
              visible: _showRerouteButton(),
              child: Container(
                width: 46, height: 46,
                //color: Colors.purple,
                child: FlatButton(
                  //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.all(0),
                  child: rerouteImage,
                  onPressed: enabled ? widget.onRerouteButtonPressed : null,
                  shape: CircleBorder(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  AnimatedBuilder buildPing(
      {Animation<double> sizeAnim,
      Animation<double> alphaAnim,
      Color color = Colors.white}) {
    return AnimatedBuilder(
      builder: (BuildContext context, Widget child) {
        return Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha((0.5 * alphaAnim.value * 255).round())),
          width: sizeAnim.value,
          height: sizeAnim.value,
        );
      },
      animation: sizeAnim,
    );
  }

  AnimatedBuilder buildTeeter(
      double rate, int baseAlpha, double screenWidth, Animation<double> anim) {
    return AnimatedBuilder(
      builder: (BuildContext context, Widget child) {
        return Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neutral_4
                  .withAlpha(((0.4 - anim.value / 8) * baseAlpha).round())),
          width: 190 + 35 * anim.value * rate,
          height: 190 + 35 * anim.value * rate,
        );
      },
      animation: anim,
    );
  }

  @override
  void dispose() {
    _teeterAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }
}

/// offset a 0.0 - 1.0 animation by the specified amount, modulo the range.
/// i.e. for an offset of 0.5:
///   0.25->0.75
///   0.75 -> 0.25
class OffsetPhaseAnimation extends Animatable<double> {
  double offset = 0.5;

  OffsetPhaseAnimation(this.offset);

  @override
  double transform(double t) {
    var raw = t + offset;
    return raw > 1.0 ? raw - 1.0 : raw;
  }
}
