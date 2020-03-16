import React from "react";

import Chart from 'react-apexcharts'

export default class RadialProgress extends React.Component {
  constructor(props) {
    super(props);

    let trackColors = {
      RUNNING: "#e0e7fe",
      PAUSED: "#e0e7fe",
      PAUSED: "rgb(240, 243, 255)",
      DONE: "rgb(197, 233, 252)",
    };

    let graphColors = {
      RUNNING: "#55c1f5",
      PAUSED: "rgb(218, 226, 237)",
      DONE: "rgb(224, 246, 255)",
    }

    this.state = {
      options: {
        plotOptions: {
          radialBar: {
            startAngle: -100,
            endAngle: 100,
            track: {
              background: trackColors[props.status],
            },
            dataLabels: {
              name: {
                fontFamily: undefined,
                fontSize: '9px',
                textTransform: 'uppercase',
                color: "lightgray",
                offsetY: 10
              },
              value: {
                fontFamily: undefined,
                offsetY: -25,
                fontSize: '23px',
                color: undefined,
                formatter: function (val) {
                  return val;
                }
              }
            }
          }
        },
        stroke: {
          dashArray: 2
        },
        labels: ['Percent'],
        colors: [graphColors[props.status]],
      },
    }
  }

  render() {
    let percent = this.props.full > 0 ? Math.round(100*this.props.part/this.props.full) : 0
    return (


      <div style={{minHeight: 150}}>
        <Chart
          options={this.state.options}
          series={[percent]}
          type="radialBar"
        />

      </div>


    );
  }
}
