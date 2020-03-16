import React from 'react'

export default class SwitchPercentageAbsolute extends React.Component {
  percentString() {
    return Math.round(100*(this.props.part/this.props.full))+"%";
  }

  render () {
    if (!this.props.full) {
      return (
        <div aria-label={this.props["aria-label"]} style={this.props.style}>
          <div>
            { this.props.part }
          </div>
        </div>
      );
    }
    return (
      <div className="hoverSwitch" style={this.props.style}>
        <div className="visibleOffHover" aria-label={this.props["aria-label"]}>
          { this.percentString() }
        </div>
        <div className="visibleOnHover" aria-label={this.props["aria-label"]}>
          { this.props.part }
        </div>
      </div>
    )
  }
}
