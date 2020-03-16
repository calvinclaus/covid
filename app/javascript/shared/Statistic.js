import React from 'react'
import SwitchPercentageAbsolute from "../frontend/SwitchPercentageAbsolute.js"
import RoundFontAwesome from "../frontend/RoundFontAwesome.js";
import moment from "moment";
import { Header, Card, Placeholder, } from 'semantic-ui-react'
import StatisticsTable from "../frontend/StatisticsTable.js";
import RepliedAfterStage from "../frontend/RepliedAfterStage.js";
import PartAndFull from "../frontend/PartAndFull.js";
import StatisticPerTimePeriodGraph from "../frontend/StatisticPerTimePeriodGraph.js";
import _ from "underscore"
import axios from "axios";


export default class Statistic extends React.Component {

  spreadReversedOrEmptyArray(array) {
    if (!present(array)) { return [] }
    return [...array].reverse()
  }

  render() {
    let model = this.props.model;
    let percent = Math.round(100*(model.numDelivered/model.targetAudienceSize))
    let relevantQueryStatistics = present(model.queryStatistics) ? model.queryStatistics.filter(s => s.numDelivered >= 100) : null;
    let relevantSearchStatistics = present(model.searchStatistics) ? model.searchStatistics.filter(s => s.numDelivered >= 100) : null;
    let relevantCampaignStatistics = present(model.campaignStatistics) ? model.campaignStatistics.filter(s => s.numDelivered >= 20) : null;

    return (
      <div className="campaignDetail">
        <Header as="h1" style={{marginBottom: 30}}>
          Analytics
          <Header.Subheader>
            {model.name}
          </Header.Subheader>
        </Header>

        <div className="flex flex-space-between">
          <StatBox
            faClasses={"far fa-envelope"}
            color="rgb(139, 85, 231)"
            part={model.numDelivered}
            full={model.nextMilestone}
            description="Requested"
          />
          <StatBox
            faClasses={"fas fa-user-check"}
            color="rgb(0, 32, 242)"
            part={model.numAccepted}
            full={model.numDelivered}
            description="Connected"
          />
          <StatBox
            faClasses={"fas fa-comment-dots"}
            color="rgb(17, 193, 210)"
            part={model.numAnswered}
            full={model.numAccepted}
            description="Responded"
          >
            <div className="stack with-margin">
              <RepliedAfterStage statistic={model} />
            </div>
          </StatBox>
        </div>


        <StatisticPerTimePeriodGraph
          loading={this.props.loading}
          monthly={this.spreadReversedOrEmptyArray(model.monthlyStatistics)}
          weekly={this.spreadReversedOrEmptyArray(model.weeklyStatistics)}
          daily={this.spreadReversedOrEmptyArray(model.dailyStatistics)}
          segments={this.spreadReversedOrEmptyArray(model.segmentedStatistics)}
          queries={this.spreadReversedOrEmptyArray(relevantQueryStatistics)}
          searches={this.spreadReversedOrEmptyArray(relevantSearchStatistics)}
          campaigns={this.spreadReversedOrEmptyArray(relevantCampaignStatistics)}
        />

      {present(relevantSearchStatistics) && !this.props.loading &&
          <div>
            <Header as="h2" style={{marginTop: 60, marginBottom: 30}}>Searches</Header>
            <StatisticsTable
              firstColName="Search"
              statistics={relevantSearchStatistics}
              periodType={"searches"}
            />
          </div>

      }

      {present(relevantCampaignStatistics) && !this.props.loading &&
          <div>
            <Header as="h2" style={{marginTop: 60, marginBottom: 30}}>Campaigns</Header>
            <StatisticsTable
              firstColName="Campaigns"
              statistics={relevantCampaignStatistics}
              periodType={"campaigns"}
            />
          </div>

      }


      <Header as="h2" style={{marginTop: 60, marginBottom: 30}}>Monthly View</Header>
      { this.props.loading ?
          <div>
            {
              [0,1,2,3,4,5].map((i) => {
                return <div
                    key={i}
                    style={{ boxShadow: "2px 2px 22px #c2e1f1", fontSize: "18px", background: "#fff", marginBottom: "50px", borderRadius: "9px", padding: "20px 20px 20px 25px", border: "2px solid #53c1f8", }}
                  >
                  <Placeholder length={"full"} style={{width:"100%", maxWidth: "none"}}>
                    <Placeholder.Header>
                      <Placeholder.Line length={"very long"}/>
                      <Placeholder.Line />
                      <Placeholder.Line />
                      <Placeholder.Line length={"medium"}/>
                    </Placeholder.Header>
                  </Placeholder>
                </div>
              })
            }
          </div>
          :
          <StatisticsTable
            firstColName="Month"
            statistics={model.monthlyStatistics}
            periodType={"monthly"}
          />
      }

      {present(relevantQueryStatistics) &&
          <div>
            <Header as="h2" style={{marginTop: 60, marginBottom: 30}}>Queries</Header>
            <StatisticsTable
              firstColName="Query"
              statistics={relevantQueryStatistics}
              periodType={"queries"}
            />
          </div>
      }

      { (present(model.segmentedStatistics)) &&
          <div>
            <Header as="h2" style={{marginTop: 60, marginBottom: 30}}>Segments</Header>
            <StatisticsTable
              firstColName="Name"
              statistics={model.segmentedStatistics}
              periodType={"segments"}
            />
          </div>
      }
    </div>
    );
  }
}


class StatBox extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      switched: false,
    };
  }

  percentString() {
    return Math.round(100*(this.props.part/this.props.full))+"%";
  }

  switch() {
    this.setState({switched: !this.state.switched})
  }

  render() {
    let switchable = !!this.props.children;
    let switched = this.state.switched;
    return (
      <div className="statBox">
        { switchable && <button className={"circular mini ui icon button toggle "+ (switched && "active")} onClick={this.switch.bind(this)}>
          <i className="icon fas fa-info"></i>
        </button>}
        <div className="symbolContainer">
          <RoundFontAwesome
            faClasses={this.props.faClasses}
            color={this.props.color}
            width="54px"
            fontSize="20px"
          />
        </div>
        { switched ? this.props.children : <div className="rightContainer">
          <PartAndFull className={"huge"} part={this.props.part} full={this.props.full} />
          <div className="description">
            {this.props.description}
          </div>
        </div>
        }
      </div>
    );
  }
}

function present(x) {
  if (typeof x === "object" && _.isEmpty(x)) return false;
  if (Array.isArray(x) && x.length == 0) return false;
  if (typeof x === "undefined" || !x || (typeof x === "String" && x.trim() == "") || x == null) return false;
  return true;
}
