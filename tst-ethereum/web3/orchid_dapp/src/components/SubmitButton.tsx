import React from "react";

export const SubmitButton: React.FC<{
  onClick: () => void,
  enabled: boolean
}> = (props) => {
  return (
    <div className="submit-button">
      <button
        onClick={(_) => {
          props.onClick();
        }}
        disabled={!props.enabled}>
        <span>Submit</span></button>
    </div>
  );
};


