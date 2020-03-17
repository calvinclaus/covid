import React from "react";
import Chart from 'react-apexcharts'
import _ from "underscore";
import pad from "array-pad";
import { statsBetween } from "./StatisticHelpers.js";

export default class DoublingRateGraph extends React.Component {
  render () {
    return (
      <Plot statistics={this.props.statistics} />
    )
  }
}



class Plot extends React.Component {

  perc(part, full) {
    if (!full) return 0;
    return Math.round(100*part/full);
  }

  getGraphConfig() {
    let { statistics, } = this.props;
    console.log(statistics);

    var periods = [];
    var daysToDouble = [];
    var growthRates = [];
    for (var i = 9; i < statistics.length; i++) {
      let stats = statsBetween(statistics[i], statistics[i-1]);
      let date = new Date(statistics[i].at)
      periods.push(`${date.getDate()}.${date.getMonth()+1}.${date.getFullYear()}`);
      daysToDouble.push(stats.daysToDouble);
    }
    console.log("growth rates: ", growthRates);


    return {
      options:  {
        legend: {
          position: "top",
          horizontalAlign: "left",
          floating: true,
          offsetX: 50,
          offsetY: -5,
          fontSize: '13px',
          fontFamily: '\'Source Sans Pro\', \'Helvetica Neue\', Arial, Helvetica, sans-serif',
          labels: {
            colors: "rgb(138, 152, 171)",
          },
          markers: {
            width: 11,
            height: 11,
            radius: "50%",
            offsetX: 61,
          },
          itemMargin: {
            horizontal: 0,
          },
        },
        annotations: {
          xaxis: [
          {
            x: 11,
            strokeDashArray: 0,
            borderColor: '#775DD0',
            label: {
              borderColor: '#775DD0',
              style: {
                color: '#fff',
                background: '#775DD0',
              },
              text: 'Quarantäne Beginn',
            }
          },
          ]
        },
        tooltip: {
          enabled: false,
        },
        grid: {
          show: true,
          borderColor: 'rgba(151, 181, 222, 0.5)',
          strokeDashArray: 4,
          position: 'back',
          xaxis: {
            lines: {
              show: false,
            }
          },
          yaxis: {
            lines: {
              show: true,
            }
          },
        },
        chart: {
          toolbar: {
            show: false,
          },
          fontFamily: '\'Source Sans Pro\', \'Helvetica Neue\', Arial, Helvetica, sans-serif',
          type: 'line',
          events: {
            markerClick: function(event, chartContext, { seriesIndex, dataPointIndex, config}) {
              let url = links[dataPointIndex]
              if (url) {
                window.open(url, getLinkTarget(url))
              }
            }
          },
        },
        colors: ['rgb(156, 194, 255)'],
        dataLabels: {
          enabled: false
        },
        markers: {
          size: 5
        },
        stroke: {
          width: 2,
          curve: 'straight',
          show: true,
          colors: ['rgb(156, 194, 255)'],
        },

        xaxis: {
          axisBorder: {
            show: true,
            color: 'rgba(151, 181, 222, 1)',
            offsetY: -1,
          },
          categories: periods,
          lines: {
            show: true
          },
          axisTicks: {
            show: false,
          },
          labels: {
            minHeight: 30,
            style: {
              colors: pad([], periods.length, "rgb(138, 152, 171)"),
            },
          },
        },

        yaxis: {
          axisBorder: {
            show: true,
            color: 'rgba(151, 181, 222, 0.5)',
            offsetX: 2,
            offsetY: -2,
          },
          forceNiceScale: true,
          lines: {
            show: true
          },
          labels: {
            minWidth: 55,
            style: {
              color: "rgb(138, 152, 171)",
            },
            formatter: (value) => { return Math.round(value)+" Tage" },
          },
        },
        fill: {
          opacity: 1

        },
        tooltip: {
          x: {
            show: true,
          },
          y: {
            show: true,
            formatter: (val, { seriesIndex }, bar) => {
              return val.toFixed(2) + " Tage";
            }
          }
        }
      },
      series: [{
        name: 'Verdopplungszeit',
        data: daysToDouble,
      },
      ],
    }

  }

  render() {
    let { options, series } = this.getGraphConfig();
    return (
      <div>
        <Chart
          options={options}
          series={series}
          height="320px"
          type="line"
        />
      </div>
    );
  }
}
