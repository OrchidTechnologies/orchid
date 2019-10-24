import React from "react";
import './DebugPanel.css'
import {OrchidAPI} from "../api/orchid-api";
import {Container} from "react-bootstrap";

export const DebugPanel: React.FC = () => {
  return (
      <Container className="form-style">
        <label className="title">Debug Output</label>
        <div style={{marginTop: '8px'}}>
          <div className="DebugPanel-container">
            <div id="log-output" className="DebugPanel-log"
                 dangerouslySetInnerHTML={{__html: OrchidAPI.shared().debugLog}}>
            </div>
          </div>
        </div>
      </Container>
  );
};

