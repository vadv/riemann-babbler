require 'net/http/server'
require 'json'

class Riemann::Responder

  def initialize(port = 55755, logger)
    @port = port
    @logger = logger
    @started_at = Time.now.to_i
  end

  def info
    {
      :version => Riemann::Babbler::VERSION,
      :ruby => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}",
      :uptime => Time.now.to_i - @started_at
    }
  end

  def start
    Thread.new {
      @logger.unknown "Start responder 0.0.0.0:#{@port}"
      Net::HTTP::Server.run(:port => @port) do |request, stream|
        @logger.unknown "Responder request: #{request}"
        [200, {'Content-Type' => 'application/json'}, [info.to_json]]
      end
    }
  end
end