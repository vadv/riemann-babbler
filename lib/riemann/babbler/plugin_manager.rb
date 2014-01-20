module Riemann
  module Babbler
    class PluginManager

      include Riemann::Babbler::Logging
      include Riemann::Babbler::Errors

      CHECK_ALIVE_PLUGINS = 10

      def initialize(sender, array_of_klasses)
        @plugins = array_of_klasses
        @sender  = sender
        @mapping = Hash.new
      end

      def run!
        @plugins.map do |plugin|
          unless plugin.new(@sender).send(:run_plugin)
            log :unknown, "Disable plugin: #{plugin}, because it not started by condition: run_plugin"
            next
          end
          @mapping[plugin] = run_thread(plugin)
        end
        loop do
          check_alive
          sleep CHECK_ALIVE_PLUGINS
        end
      end

      private

      def run_thread(plugin)
        Thread.new {
          log :unknown, "Start plugin #{plugin}"
          plugin.new(@sender).run!
          Signal.trap('TERM') do
            shutdown
          end
        }
      end

      def check_alive
        log :debug, "Check alive of threads [#{@mapping.count}]"
        @mapping.each do |plugin, thread|
          next if thread.alive?
          begin
            thread.join
          rescue => e
            log :error, "has error #{e.class}: #{e}\n #{e.backtrace.join("\n")}"
          end
          @mapping[plugin] = run_thread(plugin)
        end
      end

      def shutdown
        exit Errors::USER_CALL_SHUTDOWN
      end

    end
  end
end
