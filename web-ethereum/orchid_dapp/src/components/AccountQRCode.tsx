import React, {useState} from "react";
import {Button} from "react-bootstrap";
import {copyTextToClipboard} from "../util/util";
import {S} from "../i18n/S";
import './AccountQRCode.css'

const QRCode = require('qrcode.react');

export const AccountQRCode: React.FC<{
  data: string | undefined,
}> = (props) => {
  const [revealed, setRevealed] = useState<boolean>(false);

  function copyCode() {
    if (props.data == null) {
      return;
    }
    copyTextToClipboard(props.data);
  }

  return (
    <div>
      <div style={{
        display: "block",
        position: "relative",
        height: 150,
        textAlign: "center",
        marginTop: "16px",
      }}>
        <div className={'qrcode'}>
          <QRCode size={150} includeMargin={true} value={props.data || ""}/>
        </div>
        <div style={{
          position: "absolute",
          width: '100%',
          height: 80,
          top: 35,
          left: 0,
          display: revealed ? "none" : "block",
          backgroundColor: "white",
          lineHeight: "80px",
          textAlign: "center",
          color: "black"
        }}
             onClick={() => setRevealed(true)}
        >{S.revealQR}
        </div>
      </div>

      <Button
        className={'link-button-style'}
        style={{
          textDecoration: 'none',
          display: "block",
          position: "relative",
          marginTop: "8px",
          marginLeft: "auto",
          marginRight: "auto",
          backgroundColor: 'transparent',
          borderStyle: 'none',
          padding: 0,
        }} variant="light" onClick={() => {
        copyCode();
      }}>{"Copy"}</Button>

    </div>
  );
};

