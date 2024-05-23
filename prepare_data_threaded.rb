require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'ap'
require_relative 'array_extension.rb'

class PrepareDataThreaded
  attr_reader

  def initialize
    Dir.mkdir('data') unless Dir.exist?('data')
  end

  def download_data
    threads = []
    (0..23_659 / 100).to_a.in_groups(4, false).each do |pages|
      threads << Thread.new { ThreadedDownloader.new(pages).download }
    end
    threads.each(&:join)
  end

  class ThreadedDownloader
    attr_reader :pages

    def initialize(pages)
      @pages = pages
    end

    def download
      pages.each do |page|
        PageDownloader.new(page).download
      end
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
      ap "DEBUG: #{Thread.current.object_id} #{page} - #{Time.now}"
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

PrepareDataThreaded.new.download_data
