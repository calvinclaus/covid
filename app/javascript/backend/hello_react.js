// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.

import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import $ from "jquery"
import CampaignSegmentsFormElement from './campaigns/CampaignSegmentsFormElement'


document.addEventListener('DOMContentLoaded', () => {
  let el = document.getElementById('campaignSegments');
  let segments = $(el).data('campaign-segments');
  ReactDOM.render(
    <CampaignSegmentsFormElement segments={segments} />,
    el
  )
})
