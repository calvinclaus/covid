module Api
  class LinkedInProfileScraperController < Api::ApiController
    def next_prospects
      scraper = LinkedInProfileScraper.find(params[:id])
      rows = scraper.next_profiles_to_scrape.uniq(&:id).map do |prospect|
        [prospect.linked_in_profile_url]
      end
      csv_string = [["profileUrl"]].concat(rows).inject([]){ |csv, row| csv << CSV.generate_line(row) }.join("")
      file = Tempfile.new("next-prospects-to-scrape-for-#{scraper.id}")
      file.write(csv_string)
      file.close
      send_file file.path, filename: "next-prospects-to-scrape.csv", type: "text/csv; charset=utf-8"
    end
  end
end
