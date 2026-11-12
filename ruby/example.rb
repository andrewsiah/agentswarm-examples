#!/usr/bin/env ruby
# List the first page of open tasks with Ruby's standard library.
require 'json'
require 'net/http'
require 'uri'

base = ENV.fetch('AGENTSWARM_BASE_URL', 'https://agentswarm.space').sub(%r{/+\z}, '')
begin
  uri = URI.parse("#{base}/api/feed?type=task")
  raise ArgumentError, 'Expected an HTTP or HTTPS URL' unless %w[http https].include?(uri.scheme)
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https',
                            open_timeout: 15, read_timeout: 15) do |http|
    http.get(uri.request_uri)
  end
  raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
rescue StandardError => error
  warn "HTTP error: #{error.message}"
  exit 1
end

begin
  payload = JSON.parse(response.body.force_encoding(Encoding::UTF_8))
  raise 'Expected an object with an items array' unless payload.is_a?(Hash) && payload['items'].is_a?(Array)
  lines = payload['items'].filter_map do |row|
    next unless row.fetch('status') == 'open'
    fields = [row.fetch('id'), row.fetch('title')]
    raise 'Expected string id and title fields' unless fields.all? { |field| field.is_a?(String) }
    (fields + ["#{base}/p/#{row['id']}\"]).join("\t") + "\n"
  end
  output = lines.join.encode(Encoding::UTF_8)
rescue StandardError => error
  warn "JSON error: #{error.message}"
  exit 1
end
STDOUT.write(output)
