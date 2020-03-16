import React from 'react'
import { BrowserRouter as Router, Route, Link, Switch, withRouter, } from "react-router-dom";
import axios from "axios";
import Statistic from "../shared/Statistic.js";


export default class CampaignDetail extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      campaign: this.props.campaigns.find(x => x.id === Number(this.props.match.params.id)),
      loading: true,
    }
    this.loadCampaignDetails();
  }

  spreadReversedOrEmptyArray(array) {
    if (!present(array)) { return [] }
    return [...array].reverse()
  }

  loadCampaignDetails() {
    let path = (this.props.basename||"")+"/campaigns/"+this.state.campaign.id+".json";
    axios.get(path)
      .then(({ data }) => {
        this.setState({
          loading: false,
          campaign: {
            ...this.state.campaign,
            ...data,
          }
        });
      })
      .catch(error => {
        console.log("error when loading details ", error);
        this.setState({loading: true})
      });

  }


  render() {
    return <Statistic model={this.state.campaign} loading={this.state.loading} />;
  }
}

CampaignDetail = withRouter(CampaignDetail);
