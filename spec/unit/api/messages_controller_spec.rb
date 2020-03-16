require 'rails_helper'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
end

RSpec.describe Api::MessagesController, type: :controller do
  it "can populate a message with DE" do
    VCR.turn_on!
    VCR.use_cassette("gender_api", record: :new_episodes) do
      get :populate_message, params: {
        message: "#llgSaluteGenderedLiebe# #lastName#!\n\nWie geht's? #foo#?",
        data: {
          name: "Calvin Claus",
          foo: "bar",
        },
        gender_country: "DE",
        key: ENV['OUR_API_KEY'],
      }
    end
    expect(response.code).to eq("200")
    expect(JSON.parse(response.body).symbolize_keys).to eq("char_count": 36, "message": "Lieber Herr Claus!\n\nWie geht's? bar?")
  end

  it "can populate a message with name christian (that failed at some point but was gender api fault)" do
    VCR.turn_on!
    VCR.use_cassette("gender_api", record: :new_episodes) do
      get :populate_message, params: {
        message: "#llgSaluteGenderedLiebe# #lastName#!\n\nWie geht's? #foo#?",
        data: {
          name: "Christian Claus",
          foo: "bar",
        },
        gender_country: "DE",
        key: ENV['OUR_API_KEY'],
      }
    end
    expect(response.code).to eq("200")
    expect(JSON.parse(response.body).symbolize_keys).to eq("char_count": 36, "message": "Lieber Herr Claus!\n\nWie geht's? bar?")
  end

  it "can populate a message with lower than min samples if accuracy high enough" do
    VCR.turn_on!
    VCR.use_cassette("gender_api", record: :new_episodes) do
      get :populate_message, params: {
        message: "#llgSaluteGenderedLiebe# #lastName#!\n\nWie geht's? #foo#?",
        data: {
          name: "Kashif Arif",
          foo: "bar",
        },
        gender_country: "DE",
        key: ENV['OUR_API_KEY'],
      }
    end
    expect(response.code).to eq("200")
    expect(JSON.parse(response.body).symbolize_keys).to eq("char_count": 35, "message": "Lieber Herr Arif!\n\nWie geht's? bar?")
  end

  it "answers with 404 if gender recognition fails" do
    VCR.turn_on!
    VCR.use_cassette("gender_api", record: :new_episodes) do
      get :populate_message, params: {
        message: "#llgSaluteGenderedSalam# #lastName#!\n\nWie geht's?",
        data: {
          name: "nonamenonnamon Badawi",
        },
        gender_country: "ALL",
        key: ENV['OUR_API_KEY'],
      }
    end
    expect(response.code).to eq("404")
    expect(JSON.parse(response.body).symbolize_keys).to eq("message": nil, "error": {"accuracy" => 0, "country" => "", "credits_used" => 0, "duration" => "26ms", "gender" => "unknown", "name" => "nonamenonnamon", "name_sanitized" => "Nonamenonnamon", "samples" => 0})
  end
end
