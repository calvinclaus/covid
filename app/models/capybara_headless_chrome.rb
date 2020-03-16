Webdrivers::Chromedriver.required_version = '2.34'
# chrome version does not implement navigator.blah 62.0.3202.45
# chrome version in use here: 62.0.3202.45
# chrome driver <-> chrome compatibility matrix https://stackoverflow.com/questions/41133391/which-chromedriver-version-is-compatible-with-which-chrome-browser-version/49618567#49618567
# chrome linux version download https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F499089%2Fchrome-linux.zip?generation=1504228301450097&alt=media
require 'webdrivers/chromedriver'

class CapybaraHeadlessChrome
  def self.new_headless_browser
    chrome_bin = ENV.fetch('CHROMIUM_BIN', nil)

    # make a directory for chrome if it doesn't already exist
    chrome_dir = File.join Dir.pwd, %w[tmp chrome]
    FileUtils.rm_rf(chrome_dir)
    FileUtils.mkdir_p chrome_dir
    user_data_dir = "--user-data-dir=#{chrome_dir}"

    options = chrome_bin ? {
      "chromeOptions" => {
        "binary" => chrome_bin,
        "excludeSwitches": %w[enable-automation],
        "args" => ["--disable-dev-shm-usage", "--no-sandbox", "--window-size=1200x600", "--headless", "--disable-gpu", user_data_dir, '--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.0 Safari/537.36', '--remote-debugging-port=9222'],
      },
    } : {
      "chromeOptions" => {
        "binary" => "/Applications/XAMPP/htdocs/webdev/llgApp/chrome-mac/Chromium.app/Contents/MacOS/Chromium",
        "args" => ["--disable-dev-shm-usage", "--no-sandbox", "--window-size=1200x600", "--headless", "--disable-gpu", user_data_dir, '--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.0 Safari/537.36'],
        "excludeSwitches": %w[enable-automation],
      },
    }
    puts options


    Capybara.configure do |config|
      config.run_server = false
      config.default_driver = :chrome
    end


    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(
        app,
        browser: :chrome,
        desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(options)
      )
    end
    Capybara.javascript_driver = :chrome
    browser = Capybara::Session.new(:chrome)
    browser
  end
end
