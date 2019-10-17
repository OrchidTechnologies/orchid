import React from "react";
import './DebugPanel.css'
import {OrchidAPI} from "../api/orchid-api";

const DebugPanel: React.FC = () => {
  return (
      <div>
        <label className="title">Debug Output</label>
        <div style={{marginTop: '8px'}}>
          <div className="DebugPanel-container">
            <div id="log-output" className="DebugPanel-log"
                 dangerouslySetInnerHTML={{__html: OrchidAPI.shared().debugLog}}>
            </div>
          </div>
        </div>
      </div>
  );
};

export default DebugPanel;
