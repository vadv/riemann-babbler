require_relative 'sender_client'

module Riemann
  module Babbler

    class Sender

      include Riemann::Babbler::Logging
      include Riemann::Babbler::Options
      include Riemann::Babbler::Errors

      HOSTNAME_FILE = '/proc/sys/kernel/hostname'
      CHECK_CLIENT_ALIVE = 10

      def initialize
        @hostname = hostname
        @riemanns = create_riemanns
        start
      end

      def <<(event)
        set_event_hostname(event)
        set_event_tags(event)
        @riemanns.each {|r| r << event }
      end

      private

      def start
        Thread.new {
          loop do
            begin
              @riemanns.each do |r|
                next if r.alive?
                log :error, "Riemann client #{r.host}:#{r.port} is died, up it"
                r.start
              end
              log :debug, "Check alive of riemann client [#{@riemanns.count}]"
              sleep CHECK_CLIENT_ALIVE
            rescue
              log :error, "Riemann client sender problem"
              exit Errors::CONNECTION_PROBLEM
            end
          end
        }
      end

      def create_riemanns
        riemanns = Array.new
        opts.riemann.host = [opts.riemann.host] if opts.riemann.host.class == String
        opts.riemann.host.each { |host| riemanns << Riemann::Babbler::Sender::Client.new(host) }
        riemanns
      end

      def set_event_tags(event)
        unless opts.riemann.tags.nil?
          event[:tags] = opts.riemann.tags unless event[:tags]
        end
      end

      def set_event_hostname(event)
        event[:host] = @hostname unless event[:host]
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
