require 'net/http/server'
require 'json'

module Riemann
  module Babbler

    class Responder


      include Riemann::Babbler::Logging
      include Riemann::Babbler::Options

      attr_accessor :port, :started_at

      def initialize
        @port       = opts.riemann.responder_port
        @started_at = Time.now.to_i
      end

      def info
        {
            :version => Riemann::Babbler::VERSION,
            :ruby    => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}",
            :uptime  => Time.now.to_i - started_at,
            :errors  => opts.errors.to_hash,
            :config  => opts.riemann.to_hash
        }
      end

      def run!
        Thread.new {
          log :unknown, "Start responder 0.0.0.0:#{port}"
          Net::HTTP::Server.run(:port => port) do |request, _|
            log :debug, "Responder request: #{request}"
            [200, { 'Content-Type' => 'application/json' }, [info.to_json]]
          end
        }
      end
    end

  end
end

