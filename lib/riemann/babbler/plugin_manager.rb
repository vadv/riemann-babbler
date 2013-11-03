module Riemann
  module Babbler
    class PluginManager

      include Riemann::Babbler::Logging

      attr_accessor :sender

      def initialize(sender, array_of_klasses)
        @plugins = array_of_klasses
        @sender  = sender
      end

      def run!
        hash_of_plugins_and_threads = Hash.new
        @plugins.map do |plugin|

          unless plugin.new(@sender).send(:run_plugin)
            log :unknown, "Disable plugin: #{plugin}, because it not started by condition: run_plugin"
            next
          end

          hash_of_plugins_and_threads[plugin] = Thread.new {
            log :unknown, "Start plugin #{plugin}"
            plugin.new(@sender).run!
          }

        end

        Signal.trap 'TERM' do
          hash_of_plugins_and_threads.values.each(&:kill)
        end

        loop {
          check_alive(hash_of_plugins_and_threads)
          sleep 10
        }
      end

      def check_alive(hash_of_plugins_and_threads)
        log :debug, "Check alive of threads [#{hash_of_plugins_and_threads.count}]"
        hash_of_plugins_and_threads.each do |plugin, thread|
          next if thread.alive?
          log :error, "Plugin: #{plugin} is #{thread.inspect}, run it..."
          hash_of_plugins_and_threads[plugin] = Thread.new {
            plugin.new(@sender).run!
          }
        end
      end

    end
  end
end