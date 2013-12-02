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
          @riemann = client
          start
        end

        def start
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
          @runner.nil? || @runner.alive?
        end

        def <<(event)
          @events.shift if @events.size < opts.riemann.backlog
          @events << event
        end

        private

        # flush events
        def flush
          return nil if @events.empty?
          while @events.size > 0
            event = @events[0]
            log :debug, "Post event via #{@host}:#{@port} : #{event.inspect}"
            Timeout::timeout(opts.riemann.timeout) {
              @riemann << event
            }
            @events.shift
          end
        end

        # riemann client connect
        def client
          sender = Riemann::Client.new(
            :host    => resolv(@host), #todo: add ttl
            :port    => @port,
            :timeout => opts.riemann.timeout
          )
          sender = sender.tcp if opts.riemann.tcp
          connect_client(sender)
        end

        #@return ipaddress of riemann server
        def resolv(host)
          begin
            ip = Resolv.new.getaddress(host)
            log :debug, "Resolv host: #{host} => #{ip}"
          rescue
            log :fatal, "Can't resolv hostname: #{host}"
            exit Errors::RESOLV_RIEMANN_SERVER
          end
          ip
        end

        #@return connect to riemann
        def connect_client(riemann)
          connect = riemann
          begin
            connect = riemann.connect if opts.riemann.tcp
            log :debug, "Connected to #{riemann.host}:#{riemann.port}"
          rescue
            log :fatal, "Can't connect to riemann server: #{riemann.host}:#{riemann.port}"
            exit Errors::INIT_CONNECT
          end
          connect
        end

      end
    end
  end
end
