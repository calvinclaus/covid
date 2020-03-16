import React from 'react'
import { Header } from 'semantic-ui-react'
import { BrowserRouter as Router, Route, Link, Switch, withRouter, } from "react-router-dom";
import CampaignPreview from "../shared/CampaignPreview.js";
import CampaignDetail from "./CampaignDetail.js";

export default class Campaigns extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      campaigns: props.initialCampaigns,
    };
  }


  render () {
    return (
      <Router basename={this.props.basename}>
        <Switch>
          { this.props.canSeeDetails &&
              <Route exact path="/campaigns/:id" render={() =>  <CampaignDetail campaigns={this.state.campaigns} canEdit={this.props.canEdit} basename={this.props.basename}></CampaignDetail> }></Route> }
              <Route path="/" render={() => <CampaignList campaigns={this.state.campaigns} canEdit={this.props.canEdit} canSeeColorCode={this.props.canSeeColorCode} canSeeDetails={this.props.canSeeDetails} canUseFilmMode={this.props.canUseFilmMode}  />}></Route>
            </Switch>
          </Router>
    )
  }
}

class CampaignList extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      noRed: false,
      noNames: false,
    }
    this.renderActions = this.renderActions.bind(this);
  }

  toggleFilmMode() {
    this.setState({
      noRed: !this.state.noRed,
      noNames: !this.state.noNames,
    })
  }

  maybeFakeNames(campaign, fakerator) {
    if (!this.state.noNames) return campaign;
    let name = "Muster Mustername";
    return {
      ...campaign,
      name: name + " LLG",
      linkedInAccountName: name,
    };
  }
  renderActions({ campaign }) {
    return (
      <div>
        { this.props.canEdit &&
            <a href={`/backend/campaigns/${campaign.id}/edit`} className="ui button" aria-label="Edit">
              <i className="far fa-edit icon"></i>
            </a>
        }
        { this.props.canSeeDetails &&
            <Link to={`/campaigns/${campaign.id}`} className="ui button" aria-label="Details">
              <i className="far fa-eye icon"></i>
            </Link>
        }
      </div>
    );
  }

  renderCampaignPreviews() {
    return this.props.campaigns.map(campaign => {
      return <CampaignPreview
        key={campaign.id}
        renderActions={this.renderActions}
        campaign={this.maybeFakeNames(campaign)}
        canSeeColorCode={this.props.canSeeColorCode}
        noRed={this.state.noRed}
      />
    });
  }

  render () {
    return (
      <div className="campaignsList">
        <Header as="h1">
          Overview
        </Header>
        <div className="campaignsHead">
          <div className="col">Campaign</div>
          <div className="col">Potential</div>
          <div className="col">Milestone</div>
          <div className="col">Requested</div>
          <div className="col">Connected</div>
          <div className="col">Responded</div>
        </div>
        <div>
          { this.renderCampaignPreviews() }
        </div>
        { this.props.canUseFilmMode && <button className={"ui labeled icon button " + (this.state.noNames ? "red" : "green") } onClick={this.toggleFilmMode.bind(this)}>
          <i className="icon camera"></i>
          { !this.state.noNames ? "Activate Screen Capture Mode" : "Recording..." }
        </button> }
      </div>
    )
  }
}
