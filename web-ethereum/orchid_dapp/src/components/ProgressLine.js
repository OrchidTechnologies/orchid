import React, { useEffect, useState } from 'react'
import './ProgressLine.css'

/// https://medium.com/@bruno.raljic/animated-multi-part-progress-bar-made-from-scratch-with-reactjs-and-css-9c1d6a4dbef7
export const ProgressLine = (
  { label, backgroundColor = '#e5e5e5', visualParts = [{ percentage: '0%', color: 'white' }] }) => {
  const [widths, setWidths] = useState(visualParts.map(() => { return 0 }))

  useEffect(() => {
    // https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame
    requestAnimationFrame(() => {
      setWidths(visualParts.map(item => { return item.percentage }))
    })
  }, [visualParts])

  return (
    <>
      <div className='progressLabel'>{label}</div>
      <div className='progressVisualFull' style={{ backgroundColor }}>
        {visualParts.map((item, index) => {
          return (
            <div
              /* eslint-disable-next-line react/no-array-index-key */
              key={index}
              style={{ width: widths[index], backgroundColor: item.color }}
              className='progressVisualPart'
            />
          )
        })}
      </div>
    </>
  )
}

export default ProgressLine
