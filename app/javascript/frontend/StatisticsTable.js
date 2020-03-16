import React from "react";
import moment from "moment";
import RepliedAfterStage from "./RepliedAfterStage.js";
import PartAndFull from "./PartAndFull.js";
import nl2br from "react-nl2br";
import { getLink, getAnchorOrName, } from "./linkHelpers.js";

export default class StatisticsTable extends React.Component {
  renderStatistics() {
    return this.props.statistics.map(statistic => {
      return <Statistic key={statistic.id} statistic={statistic} periodType={this.props.periodType} />
    });
  }

  render () {
    return (
      <div className="statisticsList">
        <div className="statisticsHead">
          <div className="col">{this.props.firstColName}</div>
          <div className="col">Timespan</div>
          <div className="col">Requested</div>
          <div className="col">Connected</div>
          <div className="col">Responded</div>
        </div>
        <div>
          { this.renderStatistics() }
        </div>
      </div>
    )
  }
}

class Statistic extends React.Component {
  l(date) {
    return moment(date).format("DD.MM.YYYY")
  }

  render() {
    let { statistic, periodType, } = this.props;
    return (
      <div
        className="statisticListItem"
        data-test-id={`statistic--${statistic.id}`}
      >
        <div style={{ gridColumn: "1/2", paddingRight: 10, }}>
          { getAnchorOrName(statistic, periodType) }
        </div>
        <div>
          <div style={{display: "inline", position: "relative"}}>
            {this.l(statistic.from)}
            <br />
            <div style={{textAlign: "center", position: "absolute", width: "100%" }}>
              -
            </div>
            <br />
            {this.l(statistic.to)}
          </div>
        </div>
        <div>
          <PartAndFull
            part={statistic.numDelivered}
            description={"Requested"}
          />
        </div>
        <div>
          <PartAndFull
            full={statistic.numDelivered}
            part={statistic.numAccepted}
            description={"Connected"}
          />
        </div>
        <div>
          <PartAndFull
            full={statistic.numAccepted}
            part={statistic.numAnswered}
            description={"Responded"}
          />
        </div>
        <div>
          <RepliedAfterStage statistic={statistic} className={"small"}/>
        </div>

      </div>
    );
  }
}
