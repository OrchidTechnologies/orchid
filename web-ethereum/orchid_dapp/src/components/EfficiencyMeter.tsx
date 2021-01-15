import React, {FC} from "react";
import {Visibility} from "../util/util";
import {Col, Row} from "react-bootstrap";
import ProgressLine from "./ProgressLine";
import {MarketConditions} from "../api/orchid-market-conditions";

export function colorForEfficiency(efficiency: number | null): string {
    if (efficiency == null) { return 'grey'}

    if (efficiency <= 0.2) {
      return "#BE092A";
    }
    if (efficiency > 0.2 && efficiency <= 0.6) {
      return"#FFD147";
    }
    return 'green';
}

export const EfficiencyMeter: FC<{ marketConditions: MarketConditions | null }>
  = (props) => {

  let marketConditions = props.marketConditions;
  let efficiencyPerc: string = marketConditions?.efficiencyPerc() ?? "";
  let efficiencyColor: string = colorForEfficiency(marketConditions?.efficiency ?? 0)

  return (
    <div style={{display: 'flex', alignItems: "baseline"}}>
      {/*<ProgressLine label="" visualParts={[{percentage: efficiencyPerc, color: efficiencyColor}]}/>*/}
      <div style={{flexGrow: 1}}>
        <ProgressLine label="" visualParts={[{percentage: efficiencyPerc, color: efficiencyColor}]}/>
      </div>
      <div style={{flexGrow: 0, textAlign: "right", marginLeft: 16}}>{efficiencyPerc}</div>
    </div>
  );
}

export const EfficiencyMeterRow: FC<{ marketConditions: MarketConditions | null, label?: string }>
  = (props) => {
  return (
    <Visibility visible={props.marketConditions !== null}>
      <Row className="form-row">
        <Col>
          <label>{props.label}</label>
        </Col>
        <Col>
          <EfficiencyMeter marketConditions={props.marketConditions}/>
        </Col>
      </Row>
    </Visibility>
  );
}