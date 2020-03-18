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

  def raw_data
      header = [ "date", "num_tested", "num_infected", "num_recovered", "num_dead", ]

      statistics = Statistic.order(at: :asc)

      rows = statistics.map do |s|
        [
          s.at.to_s,
          s.num_tested,
          s.num_infected,
          s.num_recovered,
          s.num_dead,
        ]
      end

      csv_string = [header].concat(rows).inject([]){ |csv, row| csv << CSV.generate_line(row) }.join("")
      file = Tempfile.new("rohdaten-cov19-at")
      file.write(csv_string)
      file.close
      send_file file.path, filename: "rohdaten-cov19-at.csv", type: "text/csv; charset=utf-8"
  end
end
