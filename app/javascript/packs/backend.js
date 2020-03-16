/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.  //
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import Campaigns from '../frontend/Campaigns.js';
import CompanyForm from '../backend/CompanyForm.js';
import ReactDOM from 'react-dom'
import React from 'react'
import CampaignSegmentsFormElement from '../backend/campaigns/CampaignSegmentsFormElement.js'
import SearchDetail from '../backend/searches/SearchDetail.js'

require('fomantic-ui-less/semantic.less');
require('../stylesheets/backend.scss');

const $ = require("jquery")
$(document).ready(function() {
  $('[data-form-toggle-children] button[data-toggle]').click(function() {
    $(this).closest('[data-form-toggle-children]').children().show();
    $(this).parent().hide();
  });
  $('[data-form-toggle-children]').closest('form').submit(function() {
    $('[data-form-toggle-children] div:not(:visible)').remove();
  });
});


document.addEventListener('DOMContentLoaded', () => {
  let campaignsDiv = document.getElementById('campaigns');
  if (campaignsDiv) {
    ReactDOM.render(
      <Campaigns
        initialCampaigns={$(campaignsDiv).data("campaigns")}
        basename={"/backend"}
        canEdit={$(campaignsDiv).data("can-edit")}
        canSeeDetails={$(campaignsDiv).data("can-see-details")}
        canSeeColorCode={$(campaignsDiv).data("can-see-color-code")}
        canUseFilmMode={$(campaignsDiv).data("can-use-film-mode")}
      />,
      campaignsDiv,
    )
  }
  let companyDiv = document.getElementById('companyForm');
  if (companyDiv) {
    window.timezones = $(companyDiv).data("timezones")
    ReactDOM.render(
      <CompanyForm
        initialFormData={$(companyDiv).data("company")}
      />,
      companyDiv,
    )
  }

  let searchDiv = document.getElementById('search');
  if (searchDiv) {
    ReactDOM.render(
      <SearchDetail
        search={$(searchDiv).data("search")}
      />,
      searchDiv,
    )
  }
})

document.addEventListener('DOMContentLoaded', () => {
  let div = document.getElementById('campaignSegments');
  if (!div) return
  ReactDOM.render(
    <CampaignSegmentsFormElement segments={$(div).data("campaign-segments")} />,
    div,
  )
})
