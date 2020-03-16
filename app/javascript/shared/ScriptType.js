import React from "react";

export default class ScriptType extends React.Component {
  getCss() {
    return {
      position: "absolute",
      left: "50%",
      transform: "translate(-50%, 0)",
      top: "0px",
      borderBottomRightRadius: "5px",
      borderBottomLeftRadius: "5px",
      background: (this.props.backgroundColor || "rgb(109, 192, 243)"),
      fontFamily: '"Font Awesome 5 Free"',
      fontWeight: "900",
      color: "white",
      padding: "7px 15px",
    }
  }

  render () {
    if (this.props.scriptType !== "LM") { return null; }
    return (
      <div style={this.getCss()}>{String.fromCharCode(0xf0e0)}</div>
    )
  }
}
