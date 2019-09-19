import 'package:flutter/material.dart';
import 'package:orchid/api/pricing.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/util/units.dart';

class BudgetSummaryTile extends StatefulWidget {
  String image;
  String title;
  OXT oxtValue;
  Pricing pricing;
  VoidCallback detail;
  bool preserveIconSpace; // Maintain empty space even when icon is not shown

  BudgetSummaryTile(
      {this.image, this.title, this.oxtValue, this.pricing, this.detail, this.preserveIconSpace = true});

  @override
  State<StatefulWidget> createState() {
    return new _BudgetSummaryTileState();
  }
}

class _BudgetSummaryTileState extends State<BudgetSummaryTile> {
  @override
  Widget build(BuildContext context) {
    const color = Color(0xff3a3149);

    const titleStyle = TextStyle(
        color: color,
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
        fontFamily: "SFProText-Medium",
        height: 13.0 / 11.0);
    const valueStyle = TextStyle(
        color: color,
        fontSize: 15.0,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.24,
        fontFamily: "SFProText-Regular",
        height: 20.0 / 15.0);
    const valueSubtitleStyle = TextStyle(
        color: Color(0xff766d86),
        fontSize: 11.0,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.07,
        fontFamily: "SFProText-Regular",
        height: 13.0 / 11.0);

    var oxtString = widget.oxtValue?.toStringAsFixed(2) ?? "";
    var usdString = widget.pricing?.toUSD(widget.oxtValue)?.toStringAsFixed(2) ?? "";

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.detail,
      child: Container(
        height: 64,
        child: Row(
          children: <Widget>[
            Image.asset(
              widget.image,
              color: color,
            ),
            padx(11),
            Text(widget.title, style: titleStyle),
            Spacer(),
            Row(
              children: <Widget>[
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: <Widget>[
                          Text(oxtString,
                              style: valueStyle.copyWith(
                                  fontWeight: FontWeight.bold)),
                          Text(" OXT", style: valueStyle),
                        ],
                      ),
                      Visibility(
                        visible: widget.pricing != null,
                        child: Column(
                          children: <Widget>[
                            pady(2),
                            Text("\$$usdString USD", style: valueSubtitleStyle),
                          ],
                        ),
                      ),
                    ]),
                padx(4),
                Visibility(
                  visible: widget.preserveIconSpace,
                  child: Icon(Icons.chevron_right,
                      color: widget.detail != null ? Colors.grey : Colors.transparent),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
