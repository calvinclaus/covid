class CovidController < ApplicationController
  layout 'covid'

  def show
    @current = Statistic.first
    @current_json = render_to_string(template: 'covid/current.json.jbuilder', formats: 'json', layout: false)
    render :show, formats: [:html]
  end
end
