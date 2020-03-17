import React from "react";
import PartAndFull from "./frontend/PartAndFull.js";
import RoundFontAwesome from "./frontend/RoundFontAwesome.js";
import DoublingRateGraph from "./DoublingRateGraph.js";
import { Grid, Header, } from 'semantic-ui-react';
import { statsBetween } from "./StatisticHelpers.js";

export default class Covid extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      switched: false,
    }
    this.handleSwitch = this.handleSwitch.bind(this);
  }

  handleSwitch() {
    this.setState({switched: !this.state.switched})
  }

  render () {
    let beforeBeforeCurrent = this.props.statistics[this.props.statistics.length-3];
    let beforeCurrent = this.props.statistics[this.props.statistics.length-2];
    let current = this.props.statistics[this.props.statistics.length-1];
    let { numTested, numInfected, numRecovered, numDead } = current;

    let { daysToDouble } = statsBetween(current, beforeCurrent);
    let daysToDoubleBefore = statsBetween(beforeCurrent, beforeBeforeCurrent).daysToDouble;

    return (
      <div>
        <Grid>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            {!this.state.switched && <StatBox
              faClasses={"fas fa-plus-square"}
              color="rgb(232, 95, 127)"
              part={numInfected}
              changedFrom={beforeCurrent.numInfected}
              description="Erkrankt"
              lowerIsBetter={true}
              switchable={true}
              switchSign={"fas fa-vial"}
              onSwitch={this.handleSwitch}
            /> }
            { this.state.switched && <StatBox
              faClasses={"fas fa-vial"}
              switchSign={"fas fa-plus-square"}
              color="rgb(156, 194, 255)"
              part={numTested}
              changedFrom={beforeCurrent.numTested}
              lowerIsBetter={false}
              description="Getestet"
              switchable={true}
              onSwitch={this.handleSwitch}
            /> }
          </Grid.Column>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            <StatBox
              faClasses={"fas fa-thumbs-up"}
              color="rgb(73, 204, 174)"
              part={numRecovered}
              full={numInfected}
              description="Genesen"
            />
          </Grid.Column>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            <StatBox
              faClasses={"fas fa-praying-hands"}
              color="rgb(107, 107, 107)"
              part={numDead}
              full={numInfected}
              description="Todesfälle"
            />
          </Grid.Column>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            <StatBox
              faClasses={"fas fa-chart-line"}
              color="rgb(156, 194, 255)"
              part={daysToDouble}
              changedFrom={daysToDoubleBefore}
              outerDescription="Verdoppelungszeit in Tagen"
              lowerIsBetter={false}
            />
          </Grid.Column>
        </Grid>

        <Header>
          Verdoppelungszeit in Tagen
          <Header.Subheader>
            (höher ist besser)
          </Header.Subheader>
        </Header>
        <DoublingRateGraph
          statistics={this.props.statistics}
        />


      </div>
    )
  }
}
class StatBox extends React.Component {

  percentString() {
    return Math.round(100*(this.props.part/this.props.full))+"%";
  }

  render() {
    return (
      <div className={"covidStatBox " + (this.props.outerDescription && "withOuterDescription")}>
        { this.props.switchable && <button className={"circular mini ui icon button toggle "} onClick={this.props.onSwitch}>
          <i className={"icon "+this.props.switchSign}></i>
        </button>}
        <div className="symbolContainer">
          <RoundFontAwesome
            faClasses={this.props.faClasses}
            color={this.props.color}
            width="54px"
            fontSize="20px"
          />
        </div>
        <div className="rightContainer">
          <PartAndFull part={this.props.part} full={this.props.full} changedFrom={this.props.changedFrom} lowerIsBetter={this.props.lowerIsBetter} />
          {this.props.description && <div className="description">
            {this.props.description}
          </div> }
        </div>
        {this.props.outerDescription && <div className="outerDescription description">
          {this.props.outerDescription}
        </div> }
      </div>
    );
  }
}
