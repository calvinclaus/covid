import React from "react";
import numeral from "numeral";
numeral.register('locale', 'de', {
    delimiters: {
        thousands: '.',
        decimal: ','
    },
    abbreviations: {
        thousand: 'k',
        million: 'm',
        billion: 'b',
        trillion: 't'
    },
    ordinal : function (number) {
        return ".";
    },
    currency: {
        symbol: '€'
    }
});
numeral.locale('de')

export default class PartAndFull extends React.Component {
  percentString() {
    console.log((100*(this.props.part/this.props.full)));
    return numeral((100*(this.props.part/this.props.full))).format("0.00");
  }

  changePercentage() {
    let smaller = this.props.changedFrom > this.props.part ? this.props.part : this.props.changedFrom;
    let bigger = this.props.changedFrom > this.props.part ? this.props.changedFrom : this.props.part;
    let sign = this.props.changedFrom < this.props.part ? 1 : -1;
    return (sign*100*((bigger/smaller)-1));
  }

  render() {

    let className = "large"
    if (this.props.changedFrom) {
      let changePercentage = this.changePercentage();
      let smallNumberColor = changePercentage > 0 ? "green" : "red";
      if (this.props.lowerIsBetter) {
        smallNumberColor = changePercentage < 0 ? "green" : "red";
      }
      let sign = changePercentage >= 0 ? "+" : "-";
      return (
        <div className={"partAndFull " + (className || "")}>
          <div className="bigNumber" aria-label={this.props.description}>
            {Number.isInteger(this.props.part) ? numeral(this.props.part).format() : this.props.part.toFixed(2)}&nbsp;
            <div className={`smallNumber ${smallNumberColor}`}>
              <span className="percent">{sign}</span>{numeral(Math.abs(changePercentage)).format("0.00")}<span className="percent">%</span>
            </div>
          </div>
        </div>

      );
    }

    if (typeof this.props.full === "undefined") {
      return (
        <div className={"partAndFull " + (className || "")}>
          <div className="bigNumber" aria-label={this.props.description}>
            {numeral(this.props.part).format()}
          </div>
        </div>
      );
    }

    return (
      <div className={"partAndFull " + (className || "")}>
        <div className="bigNumber" aria-label={this.props.description}>
          {numeral(this.props.part).format()}&nbsp;
          <div className="smallNumber">
          {this.props.full ? this.percentString() : "0"}<span className="percent">%</span>
</div>
        </div>
      </div>
    );
  }
}
