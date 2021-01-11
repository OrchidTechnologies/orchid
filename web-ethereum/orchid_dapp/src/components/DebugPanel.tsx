import React from "react";
import './DebugPanel.css'
import {OrchidAPI} from "../api/orchid-api";
import {Container} from "react-bootstrap";
import {SubmitButton} from "./SubmitButton";
import {S} from "../i18n/S";

export const DebugPanel: React.FC = () => {
  let api = OrchidAPI.shared();
  function doReset() {
    let wallet = api.wallet.value
    if (!api.eth || !wallet) { return; }
    api.eth.orchidReset(wallet).then();
  }
  let resetOption = <div/>;
  // If we are on a test contract offer the reset button
  if (api.eth?.contractsOverridden) {
    resetOption = (
      <SubmitButton onClick={()=>{doReset()}} enabled={true}>{S.resetAccount}</SubmitButton>
    );
  }
  return (
    <div>
      <Container className="form-style"
                 style={{marginLeft: '16px', marginRight: '16px', maxWidth: '100%'}}>
        <label className="title">{S.debugOutput}</label>
        <div style={{marginTop: '8px'}}>
          <div className="DebugPanel-container">
            <div id="log-output" className="DebugPanel-log"
                 dangerouslySetInnerHTML={{__html: OrchidAPI.shared().debugLog}}>
            </div>
          </div>
        </div>
        <p/>
      </Container>
      <p/>
      {resetOption}
    </div>
  );
};

