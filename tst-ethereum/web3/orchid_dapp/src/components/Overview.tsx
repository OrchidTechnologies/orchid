import React, {useContext} from "react";
import './DebugPanel.css'
import {Col, Row} from "react-bootstrap";
import {SubmitButton} from "./SubmitButton";
import {Route, RouteContext} from "./Route";
import './Overview.css';
import beaver from '../assets/beaver1.svg';

export const Overview: React.FC = () => {
  let {setRoute} = useContext(RouteContext);
  return (
    <div>
      <div className="Overview-box">
        <Row><Col>
          <div className="Overview-title">Welcome to your Orchid Account</div>
        </Col></Row>
        <Row style={{marginTop: '24px'}} noGutters={true}>
          <Col className="Overview-copy">
            Add, move, withdraw and connect funds here for use in the Orchid App. Your Orchid Account is linked to the wallet you first associate it with.
          </Col>
          <Col>
            <img style={{width: '82px', height: '92px', marginRight: '30px', marginBottom: '24px'}} src={beaver} alt="Beaver"/>
          </Col>
        </Row>
      </div>
      <div className="Overview-bottomText">
        Ready to start using the Orchid App? Use our suggested funding amounts and quick fund:
      </div>
      <SubmitButton onClick={() => {
        setRoute(Route.AddFunds)
      }} enabled={true}>
        Add Funds to your Account
      </SubmitButton>
    </div>
  );
};

