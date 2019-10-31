import React from "react";

export const SubmitButton: React.FC<{
  onClick: () => void,
  enabled: boolean,
  hidden?: boolean
}> = (props) => {
  return (
    <div className={"submit-button"+(props.hidden?" hidden": "")}>
      <button
        onClick={(_) => {
          props.onClick();
        }}
        disabled={!props.enabled}>
        {props.children || <span>Submit</span>}
      </button>
    </div>
  );
};


