require 'net/http/server'
require 'json'

class Riemann::Responder

  INFO = {
      :version => Riemann::Babbler::VERSION,
      :ruby => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}"
  }.freeze

  def initialize(port = 55755, logger)
    @port = port
    @logger = logger
  end

  def start
    Thread.new {
      Net::HTTP::Server.run(:port => 8080) do |request,stream|
        logger.unknown "Responder request: #{request}"
        [200, {'Content-Type' => 'application/json'}, [INFO.to_json]]
      end
    }
  end
end