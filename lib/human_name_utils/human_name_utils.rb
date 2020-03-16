require "httparty"
class HumanNameUtils
  CACHE_SETTINGS = {
    cache: 60 * 60 * 24 * 60,
    valid: 60 * 60 * 24 * 60,
    period: 0.1,
    timeout: 60,
    fail: nil,
  }.freeze
  TITLES = ["★", "ツ", "☛", "✪", "PHD", "DI Dr.", "Dr.-Ing", "Dipl.-Kfm.", "Prof.Dr.h.c.", "Prof.h.c.", "Assoc", "CIPD", "LL.M", "CEng", "FRAeS", "Dr.med.", "Dr.h.c", "Prof.", "Dr. Dr.", "hp H-P", "OA", "OÄ", "OA Dr.", "DDr.", "Ddr", "DDDr", "Dr.", "Dr", "Doz.", "Dr.med.dent", "dr-phil", "phil", "med.", "Med.", "Med", "med", "Doc", "MD", "PD", "Phd", "phd", "PHD", "PhD", "M.D.", "EDiR", "DNB", "FRCR", "MMag.", "mag.", "Mag.", "Mag.a", "Univ.", "univ.", "Dipl", "Ing", "Ing DI", "DI", "FH", "EMBA", "MBA", "mba", "Mba", "BSc", "BSC", "bsc", "MSc", "MSC", "msc", "CFA", "Bc.", "D.", "M.Sc.", "MPH", "Exec.", "exec.", ".h.c.", "Dr", "dr", "Med", "med", "MD", "PD", "Prof", "MA", "MAS", "Mas", "MAs", "PMP", "B.A.", "BA", "Tcm", "M.A.", "LLB", "Mcipd", "CMgr", "MCMI", "Ilm", "1st", "AssocCIPD", "CIWM", "BFP", "FCA", "ACEL", "MCIPP", "FdSc", "ACMI", "LCGI", "CPA", "CMA", "PG", "Dip", "HRM", "SFHEA", "PMP", "Cfcipd", "FPC", "Fcipd", "SFHEA", "CA", "ACIPD", "fCMgr", "MCIPS", "Chartered", "CertRP", "Prince2", "SHRM", "FRICS"].freeze

  def self.cleanup_name(name)
    name = RemoveEmoji::Sanitize.call(name)
    name = name.gsub(/\(.*\)/, " ").strip.gsub(/ +/, " ")
    name = name.gsub(%r{[®\!\?\:/\,\_\|]}, " ")

    word_ends = "($|^| |\\.|\\||\\,|\\!|\\:|\\-|\\_)"

    name = name.gsub(Regexp.new(word_ends + "-" + word_ends, Regexp::IGNORECASE), " ").strip.gsub(/ +/, " ")

    TITLES.map(&:downcase).sort_by(&:size).reverse.each do |title|
      name = name.gsub(Regexp.new(word_ends + Regexp.escape(title) + word_ends, Regexp::IGNORECASE), " ").strip.gsub(/ +/, " ")
    end
    name = name.gsub(".", " ")

    name.strip.gsub(/ +/, " ")
  end

  def self.clean_and_split_name(name)
    name = cleanup_name(name)
    res = OpenStruct.new(
      first: name.split(" ").first.split("-").first.capitalize,
      last: name.split(" ").last.split("-").last.capitalize,
    )
    res.last = res.last + "." if res.last.length == 1
    res
  end

  def self.gender(first_name: nil, country: "DE", min_accuracy: 70, min_samples: 50, min_accuracy_under_min_samples: 90)
    params = {name: first_name, key: ENV['GENDER_API_KEY']}
    params[:country] = country unless country == "ALL"
    params[:country] = "DE" if country.blank?

    gender_data = retry_if_nil do
      url = "https://gender-api.com/get"
      APICache.get(url + params.to_json, CACHE_SETTINGS) do
        http_response = HTTParty.get(url, query: params)
        raise "Gender API Request Failed" if http_response.code != 200 # will return nil

        JSON.parse(http_response.body)
      end
    end

    raise GenderNotFound, gender_data if gender_data.nil? || gender_data["accuracy"] < min_accuracy || (gender_data["samples"] < min_samples && gender_data["accuracy"] < min_accuracy_under_min_samples)

    gender_data["gender"]
  end

  def self.standardize_name_for_comparison(name)
    name = cleanup_name(name)
    name = name.downcase
    name = name.gsub(/ü/, "ue")
    name = name.gsub(/ö/, "oe")
    name = name.gsub(/ä/, "ae")
    name = name.gsub(/ß/, "ss")
    I18n.transliterate(name)
  end

  def self.fuzzy_equal?(n1, n2)
    return false if n1.blank? || n2.blank?

    n1 = standardize_name_for_comparison(n1).split(/( |-)/)
    n2 = standardize_name_for_comparison(n2).split(/( |-)/)

    return false unless longer_includes_all_shorter?(n1.select{ |w| w.size > 1 }, n2.select{ |w| w.size > 1 })
    return false unless longer_includes_all_shorter?(n1.map{ |w| w.chars.first }, n2.map{ |w| w.chars.first })

    true
  end

  def self.longer_includes_all_shorter?(a1, a2)
    shorter = a1.size < a2.size ? a1 : a2
    longer = a1.size >= a2.size ? a1 : a2

    shorter.all?{ |word| longer.include?(word) }
  end

  def self.retry_if_nil
    max_tries = 3
    tries = 0
    res = nil
    loop do
      res = yield
      tries += 1
      break if !res.nil? || tries > max_tries

      pp "Sleeping in rety_if_nil"
      sleep(1)
    end
    res
  end
end
class GenderNotFound < StandardError
  attr_accessor :gender_data
  def initialize(gender_data)
    self.gender_data = gender_data
  end
end
