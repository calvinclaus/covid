import React from "react";
import { setDefaultLocale, registerLocale } from "react-datepicker";
import DatePicker from "react-datepicker";

export default class CampaignSegmentsFormElement extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      segments: [
        { name: "", date: "" },
        ...props.segments,
      ]
    }
  }

  handleDateChange(segmentKey, newDate) {
    let newSegments = [...this.state.segments]
    newSegments[segmentKey].date = newDate;
    this.setState({ segments: newSegments });
  }

  addSegment() {
    this.setState({segments: [{ name: "", date: "" }, ...this.state.segments, ]});
  }

  removeSegment(key) {
    let newSegments = [...this.state.segments]
    newSegments.splice(key, 1)
    this.setState({ segments: newSegments });
  }

  renderSegments() {
    let self = this;
    return this.state.segments.map((segment, index) => {
      return (
        <div key={index}>
          <label>
            Segment Name
          <input name="campaign[segments][][name]" defaultValue={segment.name} />
          </label>
          &nbsp;
          <label>
            Start Date
          <DatePicker
            name={`campaign[segments][][date]`}
            dateFormat={"dd.MM.yyyy"}
            selected={(typeof segment.date === "string" && segment.date !== "") ? new Date(segment.date) : segment.date}
            onChange={self.handleDateChange.bind(self, index)}
          />
          </label>
          <button type="button" onClick={this.removeSegment.bind(this, index)}>Delete Segment</button>
        </div>
      );
    });
  }

  render () {
    return (
      <div style={{marginBottom: 20}}>
        <h3>Campaign Segments</h3>
        { this.renderSegments() }
        <button type="button" onClick={this.addSegment.bind(this)}>Add Segment</button>
      </div>
    )
  }
}
