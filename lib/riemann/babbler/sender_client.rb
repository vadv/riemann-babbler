require 'riemann/babbler/client'
require 'resolv'
require 'socket'

module Riemann
  module Babbler
    class Sender
      class Client

        include Riemann::Babbler::Logging
        include Riemann::Babbler::Options
        include Riemann::Babbler::Errors

        INTERVAL_FLUSH = 1

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
          @runner = Thread.new {
            while @running
              sleep INTERVAL_FLUSH
              flush
            end
            @runner = nil
          }
        end

        def stop
          @running = false
        end

        def alive?
          return false if @runner.nil?
          @runner.alive?
        end

        def <<(event)
          @events.shift if @events.size > opts.riemann.backlog
          @events << event
        end

        private

        # flush events
        def flush
          unless @events.empty?
            @riemann << @events
            log :debug, "Posted events via (#{@host}:#{@port}): #{events.inspect}"
            @events.clear
          end
        end

        # riemann client
        def build_client
          @riemann = nil 
          @riemann = Riemann::Babbler::Client.new({
            :host => Resolv.new.getaddress(@host), 
            :port => @port
          })
          @riemann
        end

      end
    end
  end
end
