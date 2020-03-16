require 'uri'
require 'net/http'

class BagFinder
  def self.check_available
    product_id = ENV['BAG_SPOTTER_BAG_TO_SPOT']
    begin
      if in_stock?(product_id) # TODO CHANGE
        puts "In Stock! Sending alerts!"
        send_in_stock_alert(product_id)
      else
        puts "Not in stock..."
      end
    # rubocop:disable Lint/RescueException
    rescue Exception => e
      pp e
      ExceptionNotifier.notify_exception(e)
    end
    # rubocop:enable Lint/RescueException
  end

  def self.send_in_stock_alert(product_id)
    numbers = ENV['BAG_SPOTTER_NUMBERS_TO_NOTIFY']
    store_url = "https://en.louisvuitton.com/eng-nl/search/#{product_id}"
    ExceptionNotifier.notify_exception(Exception.new("BAG IN STOCK! #{store_url}"))

    client = MessageBird::Client.new(ENV['MSG_BIRD_ACCESS_KEY'])
    begin
      client.voice_message_create(numbers, 'Your desired bag has just become available. This is the L.V. Bag Spotter. Love you! Over and Out!', repeat: 2)
    rescue MessageBird::ErrorException => e
      p "exception calling"
      pp e.inspect
      ExceptionNotifier.notify_exception(e)
    end

    begin
      client.message_create('BagSpotter', numbers, "Your desired bag has just become available.\nThis is the L.V. Bag Spotter.\n#{store_url}.\nLove you!\nOver and Out!")
    rescue MessageBird::ErrorException => e
      p "exception sending sms"
      puts e.backtrace
      ExceptionNotifier.notify_exception(e)
    end
    true
  end

  def self.in_stock?(sku_id)
    response = request("https://secure.louisvuitton.com/ajaxsecure/getStockLevel.jsp?storeLang=eng-nl&pageType=storelocator_section&dispatchCountry=AT&skuIdList=#{sku_id}")
    response = JSON.parse(response)
    if response[sku_id]["inStock"]
      puts "in stock!"
      true
    else
      puts "not in stock!"
      false
    end
  end

  def self.request(url, _raw = false)
    puts "requesting #{url}"

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request(request)
    if response.code != "200"
      pp "API request failed"
      raise "API request to L.V. failed with code " + response.code
    end

    response.body
  end
end
