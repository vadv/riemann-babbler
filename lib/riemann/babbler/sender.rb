require 'riemann/client'
require 'resolv'
require 'socket'

module Riemann
  module Babbler

    class Sender

      include Riemann::Babbler::Logging
      include Riemann::Babbler::Options
      include Riemann::Babbler::Errors

      attr_accessor :sender

      HOSTNAME_FILE = '/proc/sys/kernel/hostname'

      def initialize
        @sender   = build_riemann_client
        @hostname = hostname
      end

      alias :r :sender

      def build_riemann_client
        @sender = Riemann::Client.new(
            :host    => resolv(opts.riemann.host), #todo: add ttl
            :port    => opts.riemann.port,
            :timeout => opts.riemann.timeout
        )
        @sender = @sender.tcp if opts.riemann.tcp
        connect_client(@sender)
        @sender
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
        begin
          connect = @sender.connect
          log :debug, "Connected to #{riemann.host}:#{riemann.port}"
        rescue
          log :fatal, "Can't connect to riemann server: #{riemann.host}:#{riemann.port}"
          exit Errors::INIT_CONNECT
        end
        connect
      end

      def <<(event)
        symbolize_event(event)
        set_event_hostname(event)
        set_event_tags(event)
        log :debug, "Post event: #{event}"
        send_with_rescue(event, opts.riemann.timeout)
      end

      def send_with_rescue(event, timeout)
        begin
          Timeout::timeout(timeout) {
            @sender << event
          }
        rescue
          log :fatal, "Connection problem with #{@sender.host}:#{@sender.port}, exit."
          exit Errors::CONNECTION_PROBLEM
        end
      end

      def set_event_tags(event)
        unless opts.riemann.tags.nil?
          event[:tags] = opts.riemann.tags unless event[:tags]
        end
      end

      def set_event_hostname(event)
        event[:host] = @hostname unless event[:host]
      end

      def symbolize_event(event)
        event = event.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end

      def hostname
        if opts.riemann.fqdn
          hostname = Socket.gethostbyname(Socket.gethostname).first
          log :debug, "Get hostname from Socket.gethostname: #{hostname}"
        else
          hostname = File.read(HOSTNAME_FILE).strip.downcase if File.exist? HOSTNAME_FILE
          log :debug, "Get hostname from #{HOSTNAME_FILE}: #{hostname}"
        end
        hostname
      end

    end

  end
end
