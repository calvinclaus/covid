import pSBC from 'shade-blend-color';
import RoundFontAwesome from "../frontend/RoundFontAwesome.js";
import SwitchPercentageAbsolute from "../frontend/SwitchPercentageAbsolute.js"
import RadialProgress from "../frontend/RadialProgress.js"
import ScriptType from "../shared/ScriptType.js";
import React from "react";
import { Message } from 'semantic-ui-react';

export default class CampaignPreview extends React.Component {
  getColors() {
    let campaign = this.props.campaign;

    var borderColor = "rgb(109, 192, 243)"; // blau
    var shadowColor = pSBC(0.5, borderColor);

    if (!this.props.canSeeColorCode) { return { borderColor, shadowColor }; }

    let percentResponded = campaign.numAnswered/campaign.numDelivered;
    if (campaign.numDelivered < 250) {
      borderColor = "#BFC5D1";
      shadowColor = pSBC(0.2, borderColor);
    } else {
      if (percentResponded < 0.04 && !this.props.noRed) {
        borderColor = "rgb(254, 43, 56)"; // rot
        shadowColor = pSBC(0.3,  "rgba(254, 43, 56, 0.35)");
      }
      if (percentResponded >= 0.04) {
        borderColor = "rgb(109, 192, 243)"; // blau
        shadowColor = pSBC(0.5, borderColor);
      }

      if (percentResponded > .08) {
        borderColor = "rgb(238, 130, 238)";
        shadowColor = pSBC(0.5, "rgba(238, 130, 238, 0.55)");
      }
    }
    return { borderColor, shadowColor };
  }

  render () {
    let campaign = this.props.campaign;
    let { borderColor, shadowColor } = this.getColors();
    return (
      <div
        className={`campaignListItem campaignPreview`}
        data-test-id={`campaign-preview-${campaign.id}`}
        style={{ borderColor, boxShadow: "2px 2px 16px "+ shadowColor, position: "relative", }}
      >
        <ScriptType scriptType={campaign.scriptType} backgroundColor={borderColor} />
        <div style={{position: "relative", width: "220px", marginLeft: "-30px", marginTop: "-30px"}}>
          <RadialProgress
            status={statusReducer(campaign)}
            full={campaign.nextMilestone}
            part={campaign.numDelivered}
          />
          <div>
            <CampaignStatus status={campaign.status}/>
          </div>
        </div>
        <div>
          <h2 className="ui header">
            <div className="content">
              {campaign.name}
              <div className="sub header">via LinkedIn Account: {campaign.linkedInAccountName}</div>
            </div>
          </h2>
        </div>
        <div>
          <span className={`centerSymbol ${campaign.targetAudienceSize || "red"}`}>
            <RoundFontAwesome faClasses={"far fa-gem"} color="rgb(254, 62, 64)" />
            <span>{campaign.targetAudienceSize || "--" }</span>
          </span>
        </div>
        <div>
          <span className={`centerSymbol ${campaign.nextMilestone || "red"}`}>
            <RoundFontAwesome faClasses={"fas fa-flag-checkered"} color="rgb(55, 171, 61)" />
            <span>{campaign.nextMilestone || "--"}</span>
          </span>
        </div>
        <div>
          <span className="centerSymbol">
            <RoundFontAwesome faClasses={"far fa-envelope"} color="rgb(139, 85, 231)" />
            <SwitchPercentageAbsolute
              aria-label={"Requested"}
              part={campaign.numDelivered}
              full={campaign.nextMilestone}
            />
          </span>
        </div>
        <div>
          <span className="centerSymbol">
            <RoundFontAwesome faClasses={"fas fa-user-check"} color="rgb(0, 32, 242)" />
            <SwitchPercentageAbsolute
              aria-label={"Connected"}
              part={campaign.numAccepted}
              full={campaign.numDelivered}
            />
          </span>
        </div>
        <div>
          <span className="centerSymbol">
            <RoundFontAwesome faClasses={"fas fa-comment-dots"} color="rgb(17, 193, 210)" />
            <SwitchPercentageAbsolute
              aria-label={"Responded"}
              part={campaign.numAnswered}
              full={campaign.numAccepted}
            />
          </span>
        </div>
        <div className="ui icon vertical buttons actions" style={{marginLeft: 10}}>
          { this.props.renderActions(this.props) }
        </div>
        { this.props.showAdminInfo &&
          <div style={{gridColumn: "2/ span 6", paddingTop: 15, }}>
            <b>Total:</b> {campaign.numProspects || 0}&nbsp;&nbsp;
            <b>Left:</b> {campaign.numAssignedNotContactedProspects || 0}&nbsp;&nbsp;
            <b>Blacklisted:</b> {campaign.numBlacklisted || 0}&nbsp;&nbsp;
            <b>Gender Unknown:</b> {campaign.numGenderUnknown || 0}&nbsp;&nbsp;
            <b>Errors:</b> {campaign.numConnectionErrors || 0} ({campaign.numConnectionErrorsAfterDeadlineWhereErrorsCount} after deadline) &nbsp;&nbsp;
            { campaign.nextProspectsUrl && <a href={campaign.nextProspectsUrl+"&limit=5000000"}>Next&nbsp;Prospects</a> }&nbsp;&nbsp;
            { campaign.exportUrl && <a href={campaign.exportUrl}>Export CSV</a> }&nbsp;&nbsp;
            { campaign.phantombusterAgentId && <a href={"https://phantombuster.com/26621/phantoms/"+campaign.phantombusterAgentId} target="_blank">Agent&nbsp;({ campaign.phantombusterAgentId })</a>}
            { campaign.phantombusterErrors && <Message error header={"This campaign will never run."} content={campaign.phantombusterErrors} /> }
          </div>
        }
      </div>
    )
  }
}

class CampaignStatus extends React.Component {
  render () {
    if (this.props.status == "1") {
      return (
        <div className="status">
          <span className="centerSymbol">
            <i className="far fa-play-circle"></i>
          </span>
        </div>
      );
    }
    if (this.props.status == "2") {
      return (
        <div className="status" style={{color: "rgb(176, 186, 200)"}}>
          <span className="centerSymbol">
            <i className="far fa-pause-circle"></i>&nbsp;
            <i className="fas fa-comment-medical"></i>
          </span>
        </div>
      );
    }
    if (this.props.status == "3") {
      return (
        <div className="status" style={{color: "rgb(176, 186, 200)"}}>
          <span className="centerSymbol">
            <i className="far fa-pause-circle"></i>&nbsp;
            <i className="fas fa-comment-slash" style={{fontSize: 16}}></i>
          </span>
        </div>
      );
    }
    if (this.props.status == "4") {
      return (
        <div className="status" style={{color: "rgb(176, 186, 200)"}}>
          <span className="centerSymbol">
            <i className="far fa-check-circle"></i>&nbsp;
            <i className="fas fa-comment-medical"></i>
          </span>
        </div>
      );
    }
    if (this.props.status == "5") {
      return (
        <div className="status" style={{color: "rgb(176, 186, 200)"}}>
          <span className="centerSymbol">
            <i className="far fa-check-circle"></i>&nbsp;
            <i className="fas fa-comment-slash" style={{fontSize: 16}}></i>
          </span>
        </div>
      );
    }

    return null;
  }
}

function statusReducer(campaign) {
  //if (campaign.nextMilestone && campaign.nextMilestone <= campaign.numDelivered) return "DONE";
  if (campaign.status === "1") {
    return "RUNNING";
  } else if (campaign.status === "2" || campaign.status === "3") {
    return "PAUSED";
  } else {
    return "DONE";
  }
}

