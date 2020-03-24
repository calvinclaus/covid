import React from "react";
import axios from "axios";
import PartAndFull from "./frontend/PartAndFull.js";
import RoundFontAwesome from "./frontend/RoundFontAwesome.js";
import DoublingRateGraph from "./DoublingRateGraph.js";
import { Grid, Header, Segment, Form, Button, Message, } from 'semantic-ui-react';
import { statsBetween } from "./StatisticHelpers.js";

export default class Covid extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      switched: false,
      email: "",
      errorMessage: "",
      successMessage: "",
    }
    this.handleSwitch = this.handleSwitch.bind(this);
  }

  handleEmailChange(event) {
    this.setState({email: event.target.value})
  }

  handleSubmit() {
    this.setState({loading: true})
    axios.post("/create_user", { email: this.state.email })
      .then(({ data }) => {
        this.setState({loading: false, errorMessage: "", successMessage: "Erfolgreich gespeichert. Vielen Dank!"})
      })
      .catch(error => {
        console.log(error);
        console.log("setting error message");
        this.setState({loading: false, errorMessage: "Email konnte nicht gespeichert werden. Ist die Adresse korrekt eingegeben?"})
      })
  }

  handleSwitch() {
    this.setState({switched: !this.state.switched})
  }

  render () {
    let beforeCurrent = this.props.statistics[this.props.statistics.length-2];
    let current = this.props.statistics[this.props.statistics.length-1];
    let { numTested, numInfected, numRecovered, numDead } = current;

    let currentStats = statsBetween(current, beforeCurrent);
    let currentStatsReversed = statsBetween(beforeCurrent, current);

    let daysToDouble = statsBetween(current, this.props.statistics[this.props.statistics.length-4]).daysToDouble;
    let daysToDoubleBefore = statsBetween(beforeCurrent, this.props.statistics[this.props.statistics.length-5]).daysToDouble;

    console.log(this.state.errorMessage);

    return (
      <div>
        <Grid>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            <StatBox
              faClasses={"fas fa-vial"}
              color="rgb(156, 194, 255)"
              part={numTested}
              changedFrom={beforeCurrent.numTested}
              lowerIsBetter={false}
              description="Getestet"
            />
          </Grid.Column>
          <Grid.Column mobile={16} tablet={8} computer={4}>
            <StatBox
              faClasses={"fas fa-hand-holding-medical"}
              color="rgb(232, 95, 127)"
              part={numInfected}
              changedFrom={numInfected/(1+currentStats.extrapolated24hChange)}
              description="Erkrankt"
              lowerIsBetter={true}
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
              faClasses={"fas fa-viruses"}
              color="rgb(143, 103, 235)"
              part={daysToDouble}
              changedFrom={daysToDoubleBefore}
              outerDescription="Verdoppelungszeit in Tagen"
              lowerIsBetter={false}
            />
          </Grid.Column>
        </Grid>

        <Segment>

        <Header>
            Verdoppelungszeit in Tagen
            <Header.Subheader>
              (höher ist besser)
            </Header.Subheader>
          </Header>
          <DoublingRateGraph
            statistics={this.props.statistics}
          />
          <Grid>
            <Grid.Column>
              <p style={{textAlign: "center",  fontSize: 11}}>
                Die Verdoppelungszeit berücksichtigt für jedes Datum die Veränderung der Infektionsrate der vorangegangenen drei Tage.<br />
                Die in der "Erkrankt"-Box angezeigte prozentuelle Veränderung, ist die prozentuelle Änderung in 24h. <br/> Sofern die Daten von 15:00 des heutigen Tages noch nicht vorhanden sind, wird die Veränderung von gestern 15:00 zu heute 8:00 auf 24h exponentiell extrapoliert.<br />
                Die in der "Getestet"-Box angezeigte prozentuelle Veränderung, ist die prozentuelle Änderung seit der letzten Messsung.
              </p>
            </Grid.Column>
          </Grid>
        </Segment>
        <Grid>
          <Grid.Column>
            <Segment>
              <div id="email">
                <Header>
                  Benachrichtigung über COVID-19 Verlauf in Österreich
                  <Header.Subheader>
                    Zwei mal täglich
                  </Header.Subheader>
                </Header>
                <p>Erhalten Sie eine Benachrichtigung sobald das Sozialministerium neue Werte veröffentlicht. Jederzeit abbestellbar.</p>
                <Form>
                  { this.state.errorMessage && <Message
                    negative
                    content={this.state.errorMessage}
                  /> }
                  { this.state.successMessage && <Message
                    content={this.state.successMessage}
                  /> }
                  <Form.Field>
                    <label>Email</label>
                    <input placeholder='Email' name="email" value={this.state.email} onChange={this.handleEmailChange.bind(this)}/>
                  </Form.Field>
                  <Button type='submit' loading={this.state.loading} onClick={this.handleSubmit.bind(this)}>Benachrichtigungen erhalten</Button>
                </Form>
              </div>
            </Segment>
          </Grid.Column>
        </Grid>


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
        { this.props.switchable && <button className={"circular small ui icon button toggle "} onClick={this.props.onSwitch}>
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
