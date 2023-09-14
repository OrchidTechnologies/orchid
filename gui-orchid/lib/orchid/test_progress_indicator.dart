import 'package:flutter/material.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/test_app.dart';

void main() {
  runApp(TestApp(content: _Test()));
}

class _Test extends StatelessWidget {
  const _Test({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var high = 0.8;
    var medium = 0.5;
    var low = 0.28;
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OrchidCircularEfficiencyIndicators.small(high),
            pady(24),
            OrchidCircularEfficiencyIndicators.small(medium),
            pady(24),
            OrchidCircularEfficiencyIndicators.small(low),
          ],
        ),
        padx(48),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OrchidCircularEfficiencyIndicators.medium(high),
            pady(24),
            OrchidCircularEfficiencyIndicators.medium(medium),
            pady(24),
            OrchidCircularEfficiencyIndicators.medium(low),
          ],
        ),
        padx(50),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OrchidCircularEfficiencyIndicators.large(high),
            pady(24),
            OrchidCircularEfficiencyIndicators.large(medium),
            pady(24),
            OrchidCircularEfficiencyIndicators.large(low),
          ],
        )
      ],
    ));
  }
}
