import React from "react";
import pSBC from 'shade-blend-color';

export default class RoundFontAwesome extends React.Component {
  render () {
    return (
      <div className={"flex-center"} style={{
        margin: "0px auto 10px auto",
        borderRadius: "50%",
        width: this.props.width || 38,
        height: this.props.width || 38,
        background: pSBC(0.65, this.props.color),
        color: this.props.color,
      }}>
      <i
        className={this.props.faClasses}
        style={{
          fontSize: this.props.fontSize || "normal",
        }}
      ></i>
      </div>
    )
  }
}



