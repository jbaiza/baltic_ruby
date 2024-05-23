require 'ap'
require 'json'
require_relative 'array_extension.rb'

class ProcessData
  attr_reader :file_contents

  def initialize
    @file_contents = []
  end

  def read_pages
    page = 0
    loop do
      break unless read_page(page)

      page += 1
    end
  end

  def read_page(page)
    file_path = File.join('data', "data_#{page}.json")
    return false unless File.exist?(file_path)

    file_contents << File.read(file_path)
    true
  end

  def process
    file_contents.each do |content|
      json_data = parse_json(content)
    end
  end

  def parse_json(content)
    JSON.parse(content)
  end

  def process_threaded
    threads = []
    file_contents.in_groups(4, false).each do |contents|
      threads << Thread.new { contents.each { |content| parse_json(content) } }
    end
    threads.each(&:join)
    true
  end
end

process_data = ProcessData.new
ap "START: #{Time.now.strftime('%H:%M:%S.%L')}"
process_data.read_pages
ap "FILES LOADED: #{Time.now.strftime('%H:%M:%S.%L')}"
process_data.process
ap "JSON PARSED: #{Time.now.strftime('%H:%M:%S.%L')}"
process_data.process_threaded
ap "JSON THREADED: #{Time.now.strftime('%H:%M:%S.%L')}"
