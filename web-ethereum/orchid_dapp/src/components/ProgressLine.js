import React, {useEffect, useState} from "react";
import "./ProgressLine.css";

/// https://medium.com/@bruno.raljic/animated-multi-part-progress-bar-made-from-scratch-with-reactjs-and-css-9c1d6a4dbef7
export const ProgressLine = (
  {label, backgroundColor = "#e5e5e5", visualParts = [{percentage: "0%", color: "white"}]}) => {
  const [widths, setWidths] = useState(visualParts.map(() => {
    return 0;
  }));
  // const [frame, setFrame] = useState(0); // Ug.

  useEffect(() => {
    // https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame
    let request = requestAnimationFrame(() => {
        setWidths(visualParts.map(item => {
          return item.percentage;
        }));
    });
    // setFrame(request)
    return () => {
      cancelAnimationFrame(request)
    }
  }, [visualParts]);

  return (
    <div>
      <div className="progressLabel">{label}</div>
      <div className="progressVisualFull" style={{backgroundColor}}>
        {visualParts.map((item, index) => {
          return (
            <div
              /* eslint-disable-next-line react/no-array-index-key */
              key={index}
              style={{width: widths[index], backgroundColor: item.color}}
              className="progressVisualPart"
            />
          );
        })}
      </div>
    </div>
  );
};

export default ProgressLine
