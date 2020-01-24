import React from "react";

export const Spacer: React.FC<{height?: number, width?: number}> = (props) => {
  if (props.height) {
    return <div style={{marginTop: `${props.height}px`}}/>
  } else {
    return <div style={{marginLeft: `${props.width}px`}}/>
  }
};


