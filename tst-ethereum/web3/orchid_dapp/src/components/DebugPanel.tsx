import React from "react";
import './DebugPanel.css'

const DebugPanel: React.FC = () => {
  return (
    <div>
      <label className="title">Debug Output</label>
      <div style={{marginTop: '8px'}}>
        <div className="DebugPanel-container">
          <div id="log-output" className="DebugPanel-log">
          </div>
        </div>
      </div>
    </div>
  );
};

export default DebugPanel;
