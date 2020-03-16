/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

require('fomantic-ui-less/semantic.less');
require('../stylesheets/frontend.scss');

import React from "react";
import ReactDOM from 'react-dom'
import $ from "jquery";
import Covid from "../Covid.js";

document.addEventListener('DOMContentLoaded', () => {

  let covidDiv = document.getElementById('covid');
  if (covidDiv) {
    console.log($(covidDiv).data("current"));
    ReactDOM.render(
      <Covid
        current={$(covidDiv).data("current")}
      />,
      covidDiv
    );
  }
})
