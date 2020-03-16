import React from "react";
import PartAndFull from "./frontend/PartAndFull.js";
import RoundFontAwesome from "./frontend/RoundFontAwesome.js";
import { Grid, Header, } from 'semantic-ui-react';

export default class Covid extends React.Component {
  render () {
    let statistic = this.props.current;
    let { numTested, numInfected, numRecovered, numDead } = statistic;
    return (
      <div>
        <Grid>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            <StatBox
              faClasses={"fas fa-vial"}
              color="rgb(156, 194, 255)"
              part={numTested}
              description="Getestet"
            />
          </Grid.Column>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            <StatBox
              faClasses={"fas fa-plus-square"}
              color="rgb(232, 95, 127)"
              part={numInfected}
              description="Erkrankt"
            />
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
        </Grid>
      </div>
    )
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
      <div className="covidStatBox">
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
