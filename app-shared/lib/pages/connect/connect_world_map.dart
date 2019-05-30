import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:orchid/pages/common/images.dart';
import 'package:orchid/util/location.dart';
import 'package:orchid/pages/common/path_dash.dart';
import 'package:orchid/pages/common/path_trim.dart';
import 'package:orchid/pages/common/paths.dart';
import '../app_colors.dart';
import 'dart:ui' as ui;

/// The shaded world map and route visualization for the connect page.
/// The provided [width] and [height] determine the widget size. The map image
/// is centered and scaled to fit the [height].
/// Note: [mapAspectRatio] is current used in the calculations for the map overlay.
class ConnectWorldMap extends StatefulWidget {
  /// Map image
  static final mapAsset = 'assets/images/3.0x/world_map.png';
  static final double mapAspectRatio = 2459.0 / 1350.0;

  /// An offset for tweaking the map image to align with real world locations.
  static Offset mapImageOffset = Offset(-0.03, 0.01);

  // The ordered list of hop locations
  final List<Location> locations;

  // Render params
  final LinearGradient _mapGradient;
  final double width;
  final double height;
  final bool showOverlay;

  const ConnectWorldMap({
    @required this.locations,
    @required LinearGradient mapGradient,
    @required this.width,
    @required this.height,
    this.showOverlay = true,
  }) : _mapGradient = mapGradient;

  @override
  _ConnectWorldMapState createState() => _ConnectWorldMapState();
}

class _ConnectWorldMapState extends State<ConnectWorldMap>
    with SingleTickerProviderStateMixin {
  AnimationController _masterAnimController;
  Animation<double> _drawRouteAnimation;

  ui.Image pinImage;

  @override
  void initState() {
    super.initState();
    _masterAnimController = AnimationController(
        duration: Duration(milliseconds: 4000), vsync: this);

    _drawRouteAnimation = CurvedAnimation(
        parent: _masterAnimController,
        curve: Interval(0, 0.5));

    Images.loadImage('assets/images/3.0x/map_pin.png').then((image) {
      setState(() {
        this.pinImage = image;
        debugPrint("image loaded: $image");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Note: Should this widget just watch the connection state directly?
    if (!widget.showOverlay) {
      _masterAnimController.stop();
    } else {
      if (widget.showOverlay && !_masterAnimController.isAnimating) {
        _masterAnimController.reset();
        _masterAnimController.repeat();
      }
    }
    return AnimatedBuilder(
        animation: _masterAnimController,
        builder: (context, snapshot) {
          return CustomPaint(
            foregroundPainter: widget.showOverlay
                ? _ConnectWorldMapOverlayPainter(widget.locations,
                    pinImage: pinImage, fraction: _drawRouteAnimation.value)
                : null,
            child: Container(
              width: widget.width,
              height: widget.height,
              // Shade the map graphic with the map gradient.
              child: Container(
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    return widget._mapGradient.createShader(
                        Rect.fromLTRB(0, 0, rect.width, rect.height));
                  },
                  blendMode: BlendMode.srcIn,
                  child: Image.asset(ConnectWorldMap.mapAsset,
                      fit: BoxFit.fitHeight),
                ),
              ),
            ),
          );
        });
  }
}

/// Paint the route visualization on the map.
/// [locations] should contain at least two Locations.
class _ConnectWorldMapOverlayPainter extends CustomPainter {
  final List<Location> locations;

  final double strokeWidth;
  final Color color;
  final bool dashed;
  final ui.Image pinImage;
  final double fraction;

  _ConnectWorldMapOverlayPainter(this.locations,
      {this.strokeWidth = 1.1,
      this.color = AppColors.teal_5,
      this.dashed = true,
      this.pinImage,
      this.fraction = 1.0});

  /// Transform a Location to canvas coordinates.
  Offset toCanvasCoordinate(Size canvasSize, Location location) {
    Offset mapOffset = location.toMercatorProjection();
    double mapHeight = canvasSize.height;
    double mapWidth = canvasSize.height * ConnectWorldMap.mapAspectRatio;
    // The map image is as tall as the canvas but may be wider or narrower.
    double x = mapWidth * (mapOffset.dx + ConnectWorldMap.mapImageOffset.dx) -
        (mapWidth - canvasSize.width) / 2;
    double y = mapHeight * (mapOffset.dy + ConnectWorldMap.mapImageOffset.dy);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (locations.length < 2) {
      return;
    }

    double scale = (size.height * ConnectWorldMap.mapAspectRatio) / size.width;

    // Generate the path segments between each location pair.
    Path path = Path();
    for (var i = 0; i < locations.length - 1; i++) {
      Location startLocation = locations[i];
      Location endLocation = locations[i + 1];
      Path nextSegment =
          _pathSegment(path, startLocation, endLocation, size, scale);
      path.addPath(nextSegment, Offset.zero);
    }

    // Trim and draw the overall path.
    if (fraction < 1.0) {
      path = PathTrim.trim(path, 0.0, fraction, false, true);
    }
    var linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * scale
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Draw the pin for each location (on top of the path).
    for (var location in locations) {
      Offset pinPoint = toCanvasCoordinate(size, location);
      _drawPin(scale, pinPoint, canvas);
    }
  }

  Path _pathSegment(Path pathIn, Location startLocation, Location endLocation,
      Size size, double scale) {
    Location midLocation = Location.midPoint(startLocation, endLocation);
    Offset start = toCanvasCoordinate(size, startLocation);
    Offset mid = toCanvasCoordinate(size, midLocation);
    Offset end = toCanvasCoordinate(size, endLocation);
    Path path = Paths.bezierThroughThreePoints(start, mid, end);
    // Note: dashing each subpath first renders better for some reason.
    if (dashed) {
      path = PathDash.dash(path,
          dashArray: CircularIntervalList([5 * scale, 3 * scale]));
    }
    return path;
  }

  void _drawPin(double scale, Offset pinPoint, Canvas canvas) {
    if (pinImage != null) {
      var pinPaint = Paint();
      pinPaint.isAntiAlias = true;
      var srcRect = ui.Rect.fromLTWH(
          0, 0, pinImage.width.toDouble(), pinImage.height.toDouble());
      // Scale the pins up at half the rate the map grows.
      var pinScale = 1 + (scale - 1) * 0.5;
      var pinSize = Size(24 * pinScale, 24 * pinScale);
      var dstRect = ui.Rect.fromCenter(
          center: pinPoint - Offset(1, pinSize.height / 2 - 1),
          width: pinSize.width,
          height: pinSize.height);
      canvas.drawImageRect(pinImage, srcRect, dstRect, pinPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
