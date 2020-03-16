class MessageUtils
  GENDERED_SALUTES = [
    {
      key: "#llgSaluteGeehrt#",
      male: "Sehr geehrter Herr",
      female: "Sehr geehrte Frau",
      unknown: "Hallo",
      ui_append: " #lastName#",
    },
    {
      key: "#llgSaluteGenderedSalam#",
      male: "Salam Mr.",
      female: "Salam Mrs.",
      unknown: "Salam",
      ui_append: " #lastName#",
    },
    {
      key: "#llgGenderedDear#",
      male: "Dear Mr.",
      female: "Dear Ms.",
      unknown: "Hey",
      ui_append: " #lastName#",
    },
    {
      key: "#llgSaluteGenderedHallo#",
      male: "Hallo Herr",
      female: "Hallo Frau",
      unknown: "Hallo",
      ui_append: " #lastName#",
    },
    {
      key: "#llgSaluteGenderedLiebe#",
      male: "Lieber Herr",
      female: "Liebe Frau",
      unknown: "Hallo",
      ui_append: " #lastName#",
    },
    {
      key: "#llgSaluteGenderedLiebeSmall#",
      male: "lieber Herr",
      female: "liebe Frau",
      unknown: "lieber Herr",
      ui_append: " #lastName#",
    },
    {
      key: "#llgSaluteGenderedInformalLiebe#",
      male: "Lieber",
      female: "Liebe",
      unknown: "Hallo",
      ui_append: " #firstName#",
    },
    {
      key: "#llgHerrFrau#",
      male: "Herr",
      female: "Frau",
      unknown: "Hallo",
    },
  ].freeze

  # throws GenderNotFound Exception
  def self.populate_message(message, data, gender_country: "DE")
    data = data.with_indifferent_access
    name = HumanNameUtils.clean_and_split_name(data[:name])
    message = message.gsub("#firstName#", name.first)
    message = message.gsub("#lastName#", name.last)
    data.keys.each do |key|
      message = message.gsub("#" + key + "#", data[key])
    end

    if includes_gendered_salute?(message)
      gender = HumanNameUtils.gender(first_name: name.first, country: gender_country)

      GENDERED_SALUTES.each do |salute|
        next unless message.include? salute[:key]

        message = message.gsub(salute[:key], salute[gender.to_sym])
      end
    end

    message
  end

  def self.includes_gendered_salute?(message)
    GENDERED_SALUTES.any?{ |s| message.include?(s[:key]) }
  end
end
