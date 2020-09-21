import React, {FC} from "react";
import { Visibility } from "../util/util";
import {Col, Row} from "react-bootstrap";
import './AddFunds.css'
import ProgressLine from "./ProgressLine";
import {MarketConditions} from "./MarketConditionsPanel";

export const EfficiencyMeter: FC<{ marketConditions: MarketConditions | null }>
  = (props) => {

  let marketConditions = props.marketConditions;
  let efficiencyPerc: string = "";
  let efficiencyColor: string = "";
  if (marketConditions != null) {
    let efficiency = marketConditions.efficiency;
    efficiencyPerc = marketConditions.efficiencyPerc();
    if (efficiency <= 0.2) {
      efficiencyColor = "red"
    }
    if (efficiency > 0.2 && efficiency <= 0.6) {
      efficiencyColor = "#FFD147"
    }
    if (efficiency > 0.6) {
      efficiencyColor = "green"
    }
  }

  return (
    <Visibility visible={marketConditions !== undefined}>
      <Row className="form-row">
        <Col>
          <label>Market efficiency</label>
        </Col>
        <Col>
          <ProgressLine label=""
                        visualParts={[{percentage: efficiencyPerc, color: efficiencyColor}]}/>
        </Col>
        <Col style={{flexGrow: 0}}>
          {efficiencyPerc}
        </Col>
      </Row>
    </Visibility>
  );
}
