import {Col, Row} from "react-bootstrap";
import RangeSlider from "react-bootstrap-range-slider";
import React from "react";
import 'react-bootstrap-range-slider/dist/react-bootstrap-range-slider.css';
// import '../css/react-bootstrap-range-slider.css';
import './EfficiencySlider.css'

export function EfficiencySlider(props: {
  value: number | null, minValue?: number,
  onChange: (changeEvent: any) => void,
  faded?: boolean
}) {
  const value = Math.round(props.value ?? 0);
  const disabledClass = (value === null) ? " disabled" : "";
  const fadedClass = (props.faded === true) ? " faded" : "";
  return <div className={"efficiency-slider" + disabledClass + fadedClass}>
    <RangeSlider
      size={"lg"}
      min={0} max={100}
      step={1}
      value={value}
      onChange={(e) => {
        if (parseFloat(e.currentTarget.value) >= (props.minValue ?? 0)-0.5) {
          props.onChange(e)
        }
      }}
      tooltip={"on"}
      tooltipPlacement={"top"}
      tooltipLabel={(value) => {
        return <span>{value}</span>
      }}
      variant={"secondary"}
    /></div>
}

export function EfficiencySliderRow(props: { value: number, onChange: (changeEvent: any) => void }) {
  return <Row className="form-row">
    <Col><label>Efficiency</label></Col>
    <Col className={"efficiency-slider"}>
      <RangeSlider
        size={"lg"}
        min={0} max={100}
        value={props.value}
        onChange={props.onChange}
        tooltip={"on"}
        tooltipPlacement={"top"}
        tooltipLabel={(value) => {
          return <span>{value}</span>
        }}
        variant={"secondary"}
      />
    </Col>
  </Row>;
}
