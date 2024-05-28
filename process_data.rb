require 'ap'
require 'json'
require 'concurrent'
require_relative 'array_extension'

class ProcessData
  attr_reader :file_contents, :file_jsons, :projects, :types, :statuses, :mutex

  def initialize
    @file_contents = []
    @mutex = Thread::Mutex.new
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
  end

  def prepare_data
    @file_jsons = []
    file_contents.each do |content|
      @file_jsons.concat JSON.parse(content)['issues']
    end
  end

  def prepare_data_threaded
    @file_jsons = []
    threads = []
    file_contents.in_groups(4, false).each do |contents|
      threads << Thread.new { Thread.current[:output] = contents.flat_map { |content| JSON.parse(content)['issues'] } }
    end
    threads.each do |thread|
      thread.join
      @file_jsons += thread[:output]
    end
  end

  def transform_data
    @projects = {}
    @types = {}
    @statuses = {}
    file_jsons.each do |issue|
      project = issue['fields']['project']
      type = issue['fields']['issuetype']
      status = issue['fields']['status']

      projects[project['key']] ||= {project: project['name'], count: 0}
      projects[project['key']][:count] += 1

      types[type['id']] ||= {type: type['name'], count: 0}
      types[type['id']][:count] += 1

      statuses[status['id']] ||= {status: status['name'], count: 0}
      statuses[status['id']][:count] += 1
    end
  end

  def transform_data_threaded
    @projects = {}
    @types = {}
    @statuses = {}
    threads = []
    file_jsons.in_groups(4, false).each do |jsons|
      threads << Thread.new do
        jsons.each do |issue|
          project = issue['fields']['project']
          type = issue['fields']['issuetype']
          status = issue['fields']['status']

          projects[project['key']] ||= {name: project['name'], count: 0}
          projects[project['key']][:count] += 1

          types[type['id']] ||= {name: type['name'], count: 0}
          types[type['id']][:count] += 1

          statuses[status['id']] ||= {name: status['name'], count: 0}
          statuses[status['id']][:count] += 1
        end
      end
    end
    threads.each(&:join)
  end

  def process_object(objects, object, key)
    mutex.synchronize do
      objects[object[key]] ||= {name: object['name'], count: 0}
      objects[object[key]][:count] += 1
    end
  end

  def transform_data_threaded_synchronize
    @projects = {}
    @types = {}
    @statuses = {}
    threads = []
    file_jsons.in_groups(4, false).each do |jsons|
      threads << Thread.new do
        jsons.each do |issue|
          project = issue['fields']['project']
          type = issue['fields']['issuetype']
          status = issue['fields']['status']

          process_object(projects, project, 'key')
          process_object(types, type, 'id')
          process_object(statuses, status, 'id')
        end
      end
    end
    threads.each(&:join)
  end

  def transform_data_threaded_concurrent
    @projects = Concurrent::Map.new
    @types = Concurrent::Map.new
    @statuses = Concurrent::Map.new
    threads = []
    file_jsons.in_groups(4, false).each do |jsons|
      threads << Thread.new do
        jsons.each do |issue|
          project = issue['fields']['project']
          type = issue['fields']['issuetype']
          status = issue['fields']['status']

          projects.compute_if_absent(project['key']) do
            {name: project['name'], count: Concurrent::AtomicFixnum.new}
          end[:count].increment

          types.compute_if_absent(type['id']) do
            {name: type['name'], count: Concurrent::AtomicFixnum.new}
          end[:count].increment

          statuses.compute_if_absent(status['id']) do
            {name: status['name'], count: Concurrent::AtomicFixnum.new}
          end[:count].increment
        end
      end
    end
    threads.each(&:join)
  end
end
