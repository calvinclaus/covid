# tries to fail to positive equality
# Amgen Austria and Amgen Holding are the same company etc.
class CompanyNameEquality
  TO_DELETE_AFTER = [
    "entsorgungsgmbh",
    "Verlagsgesellschaft m.b.H.",
    "(Europe) S.a.r.l.",
    "Vertriebs GmbH",
    "registrierte Genossenschaft mit beschränkter Haftung",
    "registrierte Genossen- schaft mit beschränkter Haftung",
    "Vertrieb für technische Gebäudeausrüstung GmbH",
    "maschinen- bau ingenieurdienstleistungen",
    "Energie- und Wassertechnik GmbH",
    "Handels- und Vermietungsgesellschaft m.b.H.",
    "produktions- und vertriebsges.m.b.h.",
    "automatisierungsgesellschaft m.b.h",
    "Internationale Transportorganisation AG",
    "gesellschaft m.b.H. & co kG",
    "vertriebs- und beratungs gmbh",
    "Gesellschaft m.b.H.",
    "Verlagsgesellschaft m.b.H.",
    "Technologies",
    "Technology",
    "IT",
    "Handels GmbH",
    "gesellschaft m.b.H",
    "ges.m.b.h.",
    "g.m.b.h",
    "m.b.h",
    "gesmbh",
    "gmbh",
    "mbh",
    "ag",
    "co",
    "kg",
    "inc",
    "pvt.",
    "ltd",
  ].freeze

  WORDS_TO_DELETE = [
    "Austria",
    "Germany",
    "Switzerland",
    "Österreich",
    "Österreichische",
    "Deutschland",
    "Deutsche",
    "Schweiz",
    "Schweizer",
    "International",
    "Hotel",
    "Hotels",
    "AT",
    "DE",
    "CH",
    "Central Eastern Europe",
    "CEE",
    "DACH",
    "EU",
    "Int",
    "die",
    "der",
    "das",
    "´",
    "edv",
    "the",
    "fa.",
    "com",
    "Company",
    "Management",
    "Consulting",
    "Immobilien",
    "Systems",
    "Software",
    "Business",
    "Holding",
    "Group",
    "Grupo",
    "GRUPO",
    "Consulting",
    "Immo",
    "e.U.",
    "Region ",
    "und",
  ].freeze

  CHARS_TO_DELETE = [
    ",",
    ".",
    "-",
    "\"",
    "â´",
    "'",
    "#",
    "=",
    "?",
    "!",
  ].freeze

  def self.with_cleaned_company_names(names)
    names.map{ |n| {clean_name: clean_name(n), name: n} }
  end

  def self.same_company?(a, b, cleaned: false)
    if cleaned
      shorter_in_longer?(a, b)
    else
      shorter_in_longer?(clean_name(a), clean_name(b))
    end
  end

  def self.shorter_in_longer?(str1, str2)
    return false if !str1.present? || !str2.present?

    longer = str1.length < str2.length ? str2 : str1
    shorter = str1.length < str2.length ? str1 : str2

    if longer.split.first == shorter.split.first
      return shorter.split.first.length >= 2
    end

    if longer.include?(shorter)
      return longer.match(Regexp.new("\\b#{Regexp.escape(shorter)}(en|s|)\\b")).present?
    end

    # int = str1.split & str2.split
    # int = int-["and"]
    # if int.present?
    #  pp "#{str1}, #{str2}, #{int}"
    # end

    false
  end

  def self.clean_name(name)
    return "" if name.blank?

    name = RemoveEmoji::Sanitize.call(name)

    I18n.locale = :en
    name = I18n.transliterate(name)

    name = name.downcase.gsub(" ", " ")
    name = name.gsub("\n", " ")
    name = name.gsub("\r", " ")
    name = name.gsub(/\(.*\)/, " ")
    name = name.gsub("&", "and")
    name = name.gsub("+", "and")

    chars_to_delete = CHARS_TO_DELETE.map{ |x| I18n.transliterate(x.downcase) }
    words_to_delete = WORDS_TO_DELETE.map{ |x| I18n.transliterate(x.downcase) }
    to_delete_after = TO_DELETE_AFTER.map{ |x| I18n.transliterate(x.downcase) }


    name_without_exclusions = name

    to_delete_after.each do |substr|
      name = name.gsub(Regexp.new("#{Regexp.escape(substr)}\\b.*"), ' ')
    end

    words_to_delete.each do |substr|
      name = name.gsub(Regexp.new("\\b#{Regexp.escape(substr)}\\b"), ' ')
    end

    chars_to_delete.each do |substr|
      name = name.gsub(Regexp.new(Regexp.escape(substr).to_s), ' ')
    end

    if name.blank?
      name = name_without_exclusions
      chars_to_delete.each do |substr|
        name = name.gsub(Regexp.new(Regexp.escape(substr).to_s), ' ')
      end
    end

    name = name.gsub(/\b.\b/, ' ')


    name = name.gsub(/\s\s+/, ' ').strip

    name = name.split(" ").slice(0, 3).join(" ")

    name
  end
end
