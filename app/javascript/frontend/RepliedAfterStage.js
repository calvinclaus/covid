import React from "react";
import PartAndFull from "./PartAndFull.js";

export default class RepliedAfterStage extends React.Component {
  render() {
    let { numRepliedAfterStage, numAnswered } = this.props.statistic;
    if (numRepliedAfterStage.length == 0) {
      return (
        <div className={"repliedAfterStage"} style={{marginLeft: 20, marginBottom: 0 }} key={1}>
          <span>No responses yet.</span>
        </div>
      )
    }
    return numRepliedAfterStage.
      sort((a, b) => { return a.followUpStageAtTimeOfReply - b.followUpStageAtTimeOfReply }).
      map((stage, index) => {
        let messageNumber = ("followUpStageAtTimeOfReply" in stage ? stage.followUpStageAtTimeOfReply : stage.follow_up_stage_at_time_of_reply)+1
        return (
          <div className={"repliedAfterStage"} style={{marginLeft: 20, marginBottom: (index === numRepliedAfterStage.length-1 ? 0 : 10)}} key={index}>
            <span className="centerSymbol" style={{display: "inline-block"}}>
              <PartAndFull
                aria-label={`Answered After Message Number ${messageNumber}`}
                part={stage.count}
                full={numAnswered}
                className={this.props.className || ""}
              />
            </span>&nbsp;<span className="textAfter"> after {messageNumber}. message</span>
          </div>
        );
      });
  }
}
