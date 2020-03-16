import React from "react";
import _ from "underscore";
import Chart from 'react-apexcharts'
import moment from "moment";
import pad from "array-pad";
import { Header, Card, Placeholder, } from 'semantic-ui-react'
import Slider from '@material-ui/core/Slider';
import DateRangePicker from '@wojtekmaj/react-daterange-picker';
import { getLinks, getLinkTarget, } from "./linkHelpers.js";

const PERIOD_TYPES = ["daily", "weekly", "monthly", "segments", "searches", "queries", "campaigns",];
const PERIOD_TYPE_TRANSLATIONS = {
  "daily": "Day",
  "weekly": "Week",
  "monthly": "Month",
  "segments": "Segment",
  "searches": "Search",
  "queries": "Query",
  "campaigns": "Campaign",
};
const PERIOD_TYPE_TRANSLATIONS_SHORT = {
  "daily": "Day",
  "weekly": "Week",
  "monthly": "Month",
  "segments": "Seg.",
  "searches": "Search",
  "queries": "Query",
  "campaigns": "Campaign",
};


export default class StatisticPerTimePeriodGraph extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      periodType: "weekly",
      dateRange: null,
    }
  }

  handleDateRangeChange(dateRange) {
    this.setState({ dateRange })
  }

  handlePeriodTypeChage(periodType) {
    this.setState({
      periodType,
      dateRange: (periodType === "queries" || periodType === "searches") ? null : this.state.dateRange,
    })
  }

  getCurrentStatistics() {
    return this.props[this.state.periodType];
  }

  getAvailablePeriodTypes() {
    return PERIOD_TYPES.filter(type => present(this.props[type]));
  }

  render() {
    return (
      <StatisticPerTimePeriodGraphPresentation
        loading={this.props.loading}
        statistics={this.getCurrentStatistics()}
        availablePeriodTypes={this.getAvailablePeriodTypes()}
        onDateRangeChange={this.handleDateRangeChange.bind(this)}
        dateRange={this.state.dateRange}
        onPeriodTypeChange={this.handlePeriodTypeChage.bind(this)}
        periodType={this.state.periodType}
      />
    );
  }
}


class StatisticPerTimePeriodGraphPresentation extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      filtersVisible: true,
    }
  }

  toggleFilters() {
    this.setState({filtersVisible: !this.state.filtersVisible})
  }

  render() {
    let { availablePeriodTypes, periodType, loading, statistics, onDateRangeChange, onPeriodTypeChange, dateRange, } = this.props;
    return (

      <div style={{position: "relative", background: "white", padding: 30, width: "100%", marginTop: 80}} className="blueBorderBox">
        <h4 style={{
          textTransform: "uppercase",
          color: "rgb(138, 152, 171)",
          letterSpacing: "0.2rem",
          fontSize: "18px",
          marginBottom: 25,
        }}>
        Requested by {PERIOD_TYPE_TRANSLATIONS[periodType]}
      </h4>
      <div style={{position: "absolute", top: 15, right: 15, }}>
        <button
          className="ui icon button"
          style={{background: "transparent", color: "rgb(138, 152, 171)"}}
          onClick={this.toggleFilters.bind(this)}
        >
          <i className="fas fa-ellipsis-h"></i>
        </button>
      </div>
      { this.state.filtersVisible &&
          <div style={{position: "absolute", background: "white", zIndex:1, top: 15, right: 15, width: 220+availablePeriodTypes.length*20, padding: "20px 30px", borderWidth: 1}} className="blueBorderBox">
            <div style={{position: "absolute", top: 0, right: 0, }}>
              <button
                className="ui icon button"
                style={{background: "transparent", color: "rgb(85, 193, 235)"}}
                onClick={this.toggleFilters.bind(this)}
              >
                <i className="fas fa-times"></i>
              </button>

            </div>
            <h4
              style={{
                textTransform: "uppercase",
                color: "rgb(138, 152, 171)",
                letterSpacing: "0.2rem",
                fontSize: "15px",
                marginTop: 0,
                marginBottom: 15,
              }}
            >
              Filter
            </h4>
            <span className="label">View</span>
            <Slider
              min={0}
              max={availablePeriodTypes.length-1}
              marks={
                availablePeriodTypes.map((type, i) => {
                  return { value: i, label: PERIOD_TYPE_TRANSLATIONS_SHORT[type] }
                })
              }
              value={availablePeriodTypes.indexOf(periodType)}
              onChange={(e, index) => onPeriodTypeChange(availablePeriodTypes[index])}
            />
            { periodType !== "queries" && periodType !== "searches" &&
                <div>
                  <span className="label">Period</span>
                  <DateRangePicker
                    format={"dd.M.y"}
                    onChange={onDateRangeChange}
                    value={dateRange}
                    maxDate={new Date()}
                    calendarIcon={null}
                    clearIcon={
                      <i style={{color:`rgba(138, 152, 171, ${!dateRange ? "0.1" : "1"})`}} className="fas fa-calendar-times"></i>
                    }
                  />
                </div>
            }

          </div>
      }

      { loading ?
          <Placeholder style={{maxWidth: "none"}}>
            <Placeholder.Image style={{width: "100%", height: 300}}/>
          </Placeholder>
          :
          <BarGraph
            periodType={periodType}
            statistics={statistics}
            dateRange={dateRange}
          />
      }
      <h4 style={{
        textTransform: "uppercase",
        color: "rgb(138, 152, 171)",
        letterSpacing: "0.2rem",
        fontSize: "18px",
        marginBottom: 25,
      }}>
      Conversion by {PERIOD_TYPE_TRANSLATIONS[periodType]}
    </h4>
    <br />
    { loading ?
        <Placeholder style={{maxWidth: "none"}}>
          <Placeholder.Image style={{width: "100%", height: 300}}/>
        </Placeholder>
        :
        <Plot
          periodType={periodType}
          statistics={statistics}
          dateRange={dateRange}
        />
    }

  </div>


    );
  }
}

class BarGraph extends React.Component {

  perc(part, full) {
    if (!full) return 0;
    return Math.round(100*part/full);
  }

  pRel(part, full, relativeTo) {
    return Math.round((this.perc(part, full)/100)*relativeTo);
  }

  getGraphConfig() {
    let { periodType, statistics, dateRange } = this.props;

    statistics = statistics.filter((statistic) => {
      if (!this.props.dateRange || !this.props.dateRange[0]) return true;
      return moment(statistic.from).isBetween(this.props.dateRange[0], this.props.dateRange[1], "[]");
    });

    let deliveredPerPeriod = statistics.map(s => s.numDelivered)
    let max = _.max(deliveredPerPeriod);
    let acceptedPerPeriod = statistics.map(s => this.pRel(s.numAccepted, s.numDelivered, max))
    let answeredPerPeriod = statistics.map(s => this.pRel(s.numAnswered, s.numAccepted, max))
    let periods = statistics.map(s => s.name);
    let links = getLinks(statistics, periodType);

    let padTo = 8;
    deliveredPerPeriod = pad(deliveredPerPeriod, padTo, null);
    acceptedPerPeriod = pad(acceptedPerPeriod, padTo, null);
    answeredPerPeriod = pad(answeredPerPeriod, padTo, null);
    periods = pad(periods, padTo, "");
    links = pad(links, padTo, null);

    let columnWidth = "25%";
    let strokeWidth = 2;
    if (periods.length > 10) {
      columnWidth = "55%";
    }
    if (periods.length > 20) {
      columnWidth = "85%";
      strokeWidth = 1;
    }

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
        grid: {
          show: true,
          borderColor: 'rgba(151, 181, 222, 0.5)',
          strokeDashArray: 4,
          position: 'back',
          xaxis: {
            lines: {
              show: true,
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
          height: 250,
          type: 'bar',
          events: {
            dataPointSelection: function(event, chartContext, { seriesIndex, dataPointIndex, config}) {
              let url = links[dataPointIndex]
              if (url) {
                window.open(url, getLinkTarget(url))
              }
            }
          },
        },
        plotOptions: {
          bar: {
            horizontal: false,
            columnWidth: columnWidth,
            endingShape: 'rounded',
          },
        },
        colors: ['rgb(131, 93, 246)', 'rgb(51, 96, 246)', 'rgb(109, 192, 243)'],
        dataLabels: {
          enabled: false
        },
        stroke: {
          show: true,
          width: strokeWidth,
          colors: ['transparent']
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
            style: {
              colors: pad([], periods.length, "rgb(138, 152, 171)"),
            },
          },
          title: {
            style: {
              color: "rgb(138, 152, 171)",
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
          labels: {
            minWidth: 55,
            style: {
              color: "rgb(138, 152, 171)",
            },
          },
          lines: {
            show: true
          }
        },
        fill: {
          opacity: 1

        },
        tooltip: {
          y: {
            formatter: (val, { seriesIndex }, bar) => {
              if (seriesIndex === 0) {
                return val + " requested"
              } else if (seriesIndex === 1) {
                return this.perc(val,max) + "% connected"
              } else if (seriesIndex === 2) {
                return this.perc(val,max) + "% responded"
              }
            }
          }
        }
      },
      series: [{
        name: 'Requested',
        data: deliveredPerPeriod,
      }, {
        name: 'Connected',
        data: acceptedPerPeriod,
      }, {
        name: 'Responded',
        data: answeredPerPeriod,
      }],
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
          type="bar"
        />
      </div>
    );
  }
}

class Plot extends React.Component {

  perc(part, full) {
    if (!full) return 0;
    return Math.round(100*part/full);
  }

  getGraphConfig() {
    let { periodType, statistics, } = this.props;

    statistics = statistics.filter((statistic) => {
      if (!this.props.dateRange || !this.props.dateRange[0]) return true;
      return moment(statistic.from).isBetween(this.props.dateRange[0], this.props.dateRange[1], "[]");
    });

    let deliveredPerPeriod = statistics.map(s => s.numDelivered)

    let convertedPerPeriod = statistics.map(s => this.perc(s.numAnswered, s.numDelivered))
    let acceptedPerPeriod = statistics.map(s => this.perc(s.numAccepted, s.numDelivered)/10)
    let answeredPerPeriod = statistics.map(s => this.perc(s.numAnswered, s.numAccepted)/10)

    let periods = statistics.map(s => s.name);

    let links = getLinks(statistics, periodType);

    let padTo = 8;
    convertedPerPeriod = pad(convertedPerPeriod, padTo, null);
    acceptedPerPeriod = pad(acceptedPerPeriod, padTo, null);
    answeredPerPeriod = pad(answeredPerPeriod, padTo, null);

    periods = pad(periods, padTo, "");

    links = pad(links, padTo, null);

    convertedPerPeriod = [...convertedPerPeriod, null]
    acceptedPerPeriod = [...acceptedPerPeriod, null]
    answeredPerPeriod = [...answeredPerPeriod, null]
    periods = [...periods, ""]


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
              show: true,
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
        colors: ['rgb(248, 198, 87)', 'rgb(51, 96, 246)', 'rgb(109, 192, 243)'],
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
          colors: ['rgb(248, 198, 87)', 'rgb(51, 96, 246)', 'rgb(109, 192, 243)'],
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
            formatter: (value) => { return Math.round(value)+"%" },
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
              if (seriesIndex === 0) {
                return val + "% converted"
              } else if (seriesIndex === 1) {
                return val*10 + "% connected"
              } else if (seriesIndex === 2) {
                return val*10 + "% responded"
              }
            }
          }
        }
      },
      series: [{
        name: 'Converted',
        data: convertedPerPeriod,
      }, {
        name: 'Connected',
        data: acceptedPerPeriod,
      }, {
        name: 'Responded',
        data: answeredPerPeriod,
      }],
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

function present(x) {
  if (typeof x === "object" && _.isEmpty(x)) return false;
  if (Array.isArray(x) && x.length == 0) return false;
  if (typeof x === "undefined" || !x || (typeof x === "String" && x.trim() == "") || x == null) return false;
  return true;
}
