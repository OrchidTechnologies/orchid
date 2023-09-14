import 'dart:math';
import 'dart:ui';

/// A geographical coordinate in degrees of latitude and longitude.
class Location {
  // Some Airport locations
  static Location SFO = Location(lat: 37.6213, long: -122.3790);
  static Location LGA = Location(lat: 47.7769, long: -73.8740);
  static Location STL = Location(lat: 38.7523, long: -90.3717);
  static Location PEK = Location(lat: 40.0799, long: 116.6031);
  static Location EZE = Location(lat: -34.8150, long: -58.5348);

  // Some Geographically recognizable locations for map alignment.
  static Location StraightOfGibralter = Location(lat: 35.9, long: -5.6);
  static Location SoutherTipOfAfrica = Location(lat: -34.53, long: 20.001);
  static Location CapeHorn = Location(lat: -55.9833, long: -67.2667);

  /// The latitude and longitude in degrees.
  final double lat;
  final double long;

  Location({required this.lat, required this.long});

  /// Perform a Mercator projection of the latitude and longitude in degrees to
  /// normalized x,y coordinates (0-1, 0-1).
  /// https://stackoverflow.com/a/14457180/74975
  Offset toMercatorProjection() {
    double latRad = _rad(lat);
    double x = (long + 180) * (1.0 / 360);
    double mercN = log(tan((pi / 4) + (latRad / 2)));
    double y = 0.5 - (mercN / (2 * pi));
    return Offset(x, y);
  }

  /// Perform a Gall stereographic projection of the latitude and longitude in degrees to
  /// normalized x,y coordinates (0-1, 0-1).
  /// https://en.wikipedia.org/wiki/Gall_stereographic_projection
  Offset toGallProjection() {
    // The projection
    double px = _rad(long) / sqrt2;
    double py = (1 + sqrt2 / 2) * tan(_rad(lat) / 2);
    // Normalized
    double xmax = 2.2214414691; // pi/sqrt2
    double ymax = 1.7071067812; // (1 + sqrt2 / 2) * tan((pi/2)/ 2)
    return Offset((px / xmax + 1) / 2, (-py / ymax + 1) / 2);
  }

  /// Calculate the mid-point of the great circle path between the
  /// [start] and [end] locations.
  static Location midPoint(Location start, Location end) {
    // Calculation from: http://www.movable-type.co.uk/scripts/latlong.html
    double lat1 = start.lat * pi / 180;
    double long1 = start.long * pi / 180;
    double lat2 = end.lat * pi / 180;
    double long2 = end.long * pi / 180;
    double bx = cos(lat2) * cos(long2 - long1);
    double by = cos(lat2) * sin(long2 - long1);
    double midlat = atan2(sin(lat1) + sin(lat2),
        sqrt((cos(lat1) + bx) * (cos(lat1) + bx) + by * by));
    double midlong = long1 + atan2(by, cos(lat1) + bx);
    midlat = midlat * 180 / pi;
    midlong = (midlong * 180 / pi + 540) % 360 - 180;
    return Location(lat: midlat, long: midlong);
  }

  static double _rad(double degrees) {
    return degrees * pi / 180;
  }

  String toString() {
    return 'Location(lat: $lat, long: $long)';
  }
}
