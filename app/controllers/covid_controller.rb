class CovidController < ApplicationController
  layout 'covid'

  def show
    @statistics = Statistic.
      where("statistics.at = (select max(i.at) from statistics i where date(i.at) = date(statistics.at))").
      order(at: :asc)
    @current = @statistics.last
    @statistics_json = render_to_string(template: 'covid/show.json.jbuilder', formats: 'json', layout: false)
    render :show, formats: [:html]
  end
end
