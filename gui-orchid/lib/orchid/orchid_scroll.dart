
// Fix excessively damped scrolling.
// Workaround for issue: https://github.com/flutter/flutter/issues/32448
import 'package:flutter/cupertino.dart';

class OrchidScrollPhysics extends ScrollPhysics {

  const OrchidScrollPhysics({ ScrollPhysics? parent }): super(parent: parent);

  @override
  OrchidScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OrchidScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        //velocity: velocity * 0.91, // TODO(abarth): We should move this constant closer to the drag end.
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }
}
