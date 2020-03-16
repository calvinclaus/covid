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
    return (100*(this.props.part/this.props.full)).toFixed(2);
  }

  render() {
    if (typeof this.props.full === "undefined") {
      return (
        <div className={"partAndFull " + (this.props.className || "")}>
          <div className="bigNumber" aria-label={this.props.description}>
            {numeral(this.props.part).format()}
          </div>
        </div>
      );
    }

    return (
      <div className={"partAndFull " + (this.props.className || "")}>
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
