require 'riemann/client'
require 'resolv'
require 'socket'

module Riemann
  module Babbler
    class Sender
      class Client

        include Riemann::Babbler::Logging
        include Riemann::Babbler::Options
        include Riemann::Babbler::Errors

        INTERVAL_FLUSH = 0.1

        attr_accessor :host, :port, :events

        def initialize(host)
          @host, @port   = host.split(':')
          @port ||= opts.riemann.port
          @events = Array.new
          start
        end

        def start
          build_client
          @running = true
          @runner = Thread.new do
            while @running
              sleep INTERVAL_FLUSH
              flush
            end
            @runner = nil
          end
        end

        def stop
          @running = false
        end

        def alive?
          !@runner.nil? || @runner.alive?
        end

        def <<(event)
          @events.shift if @events.size > opts.riemann.backlog
          @events << event
        end

        private

        # flush events
        def flush
          return nil if @events.empty?
          while @events.size > 0
            event = @events[0]
            Timeout::timeout(opts.riemann.timeout) {
              @riemann << event
            }
            @events.shift
            log :debug, "Posted event (#{@host}:#{@port}): #{event.inspect}"
          end
        end

        # riemann client
        def build_client
          @riemann = nil 
          @riemann = Riemann::Client.new({
            :host => Resolv.new.getaddress(@host), 
            :port => @port, 
            :timeout => opts.riemann.timeout
          })
          @riemann = @riemann.tcp if opts.riemann.tcp
          @riemann
        end

      end
    end
  end
end
