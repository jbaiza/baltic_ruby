require_relative 'process_data'
require 'benchmark'

begin
  process_data = ProcessData.new
  process_data.read_pages
  Benchmark.bm do |x|
    x.report(:parse) { process_data.prepare_data }
    ap "Loaded records: #{process_data.file_jsons.count}."
    x.report(:parse_threader) { process_data.prepare_data_threaded }
    ap "Loaded records: #{process_data.file_jsons.count}."
    x.report(:transform) { 100.times { process_data.transform_data } }
    ap "Projects count: #{process_data.projects.keys.count}, data count: #{process_data.projects.values.sum { |v| v[:count] }}"
    ap "Types count: #{process_data.types.keys.count}, data count: #{process_data.types.values.sum { |v| v[:count] }}"
    ap "Statuses count: #{process_data.statuses.keys.count}, data count: #{process_data.statuses.values.sum { |v| v[:count] }}"
    x.report(:transform_threaded) { 100.times { process_data.transform_data_threaded } } rescue nil
    ap "Projects count: #{process_data.projects.keys.count}, data count: #{process_data.projects.values.sum { |v| v[:count] }}"
    ap "Types count: #{process_data.types.keys.count}, data count: #{process_data.types.values.sum { |v| v[:count] }}"
    ap "Statuses count: #{process_data.statuses.keys.count}, data count: #{process_data.statuses.values.sum { |v| v[:count] }}"
    x.report(:transform_threaded_synchronize) { 100.times { process_data.transform_data_threaded_synchronize } }
    ap "Projects count: #{process_data.projects.keys.count}, data count: #{process_data.projects.values.sum { |v| v[:count] }}"
    ap "Types count: #{process_data.types.keys.count}, data count: #{process_data.types.values.sum { |v| v[:count] }}"
    ap "Statuses count: #{process_data.statuses.keys.count}, data count: #{process_data.statuses.values.sum { |v| v[:count] }}"
    x.report(:transform_data_threaded_concurrent) { 100.times { process_data.transform_data_threaded_concurrent } }
    ap "Projects count: #{process_data.projects.keys.count}, data count: #{process_data.projects.values.sum { |v| v[:count].value }}"
    ap "Types count: #{process_data.types.keys.count}, data count: #{process_data.types.values.sum { |v| v[:count].value }}"
    ap "Statuses count: #{process_data.statuses.keys.count}, data count: #{process_data.statuses.values.sum { |v| v[:count].value }}"
  end
  true
end
