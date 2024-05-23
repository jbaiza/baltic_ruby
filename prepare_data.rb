require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'ap'

class PrepareData
  attr_reader

  def initialize
    Dir.mkdir('data') unless Dir.exist?('data')
  end

  def download_data
    page = 0
    offset = 0
    limit = 100
    loop do
      PageDownloader.new(page).download
      page += 1
      offset += limit
      break if page > 23_659 / 100
    end
  end

  class PageDownloader
    attr_reader :url, :page, :limit

    def initialize(page)
      @page = page
      @limit = 100
      @url = URI("https://eazybi-jba.atlassian.net/rest/api/2/search")
    end

    def download
      ap "DEBUG: #{page} - #{Time.now}"
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = net_request
      request.body = request_body
      File.open(File.join('data', "data_#{page}.json"), 'wb') do |f|
        response = http.request(request)
        f.write(response.read_body)
      end
    end

    def request_body
      JSON.dump({jql: 'ORDER BY created', startAt: page * limit, maxResults: limit})
    end

    def net_request
      request = Net::HTTP::Post.new(url)
      request['Accept-Language'] = 'en'
      request['X-Force-Accept-Language'] = 'true'
      request['Content-type'] = 'application/json'
      request['Authorization'] = 'Basic '
      request
    end
  end
end

PrepareData.new.download_data
