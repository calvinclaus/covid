import React from "react";
import Statistic from "../../shared/Statistic.js";

export default class SearchDetail extends React.Component {
  // this little forced state change is to prevent the Statistic component from overflowing
  // a rerender prevents it
  constructor(props) {
    super(props);
    this.state = {
      search: props.search,
      loading: true,
    }
    setTimeout(() => {
      this.setState({loading: false});
    }, 200);
  }
  render () {
    return (
      <Statistic
        model={this.state.search}
        loading={this.state.loading}
      />
    )
  }
}
