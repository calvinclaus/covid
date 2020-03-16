import React from "react";

export default class PartAndFull extends React.Component {
  percentString() {
    return Math.round(100*(this.props.part/this.props.full));
  }

  render() {
    if (typeof this.props.full === "undefined") {
      return (
        <div className={"partAndFull " + (this.props.className || "")}>
          <div className="bigNumber" aria-label={this.props.description}>
            {this.props.part}
          </div>
        </div>
      );
    }

    return (
      <div className={"partAndFull " + (this.props.className || "")}>
        <div className="bigNumber" aria-label={this.props.description}>
          {this.props.part}&nbsp;
          <div className="smallNumber">
          {this.props.full ? this.percentString() : "0"}<span className="percent">%</span>
</div>
        </div>
      </div>
    );
  }
}
