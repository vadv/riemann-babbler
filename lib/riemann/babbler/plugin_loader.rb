module Riemann
  module Babbler
    class PluginLoader

      include Riemann::Babbler::Logging
      include Riemann::Babbler::Options

      AUTO_START = [
          'cpu',
          'cpu_fan',
          'cpu_temp',
          'disk',
          'disk_stat',
          'exim4',
          'la',
          'mdadm',
          'mega_cli',
          'memory',
          'net',
          'runit',
          'tw_cli',
          'errors_reporter'
      ].freeze

      attr_accessor :sender

      def initialize(riemann)
        @sender = riemann
      end

      def all_available_plugins
        default_plugins_dir = File.expand_path('../plugins/', __FILE__)
        plugins             = []
        Dir.glob(default_plugins_dir + '/*.rb') do |file|
          plugins << file
        end
        if Dir.exist? opts.riemann.plugins_directory
          Dir.glob(opts.riemann.plugins_directory + '/*.rb') do |file|
            plugins << file
          end
        else
          log :error, "Directory doesn't exists: #{opts.riemann.plugins_directory}"
        end
        plugins
      end

      def require_all_plugins
        Riemann::Babbler::Plugin.registered_plugins.clear
        all_available_plugins.each { |file| require file }
        log :debug, "Require plugins: #{Riemann::Babbler::Plugin.registered_plugins}"
        # load parent
        opts.plugins.to_hash.each do |plugin_name, plugin_opts|
          next if plugin_opts.nil?
          next unless plugin_opts.kind_of?(Hash)
          if plugin_opts.has_key? "parent"
            klass = Class.new(underscore_to_name(plugin_name))
            klass.send(:title, underscore_to_name(plugin_opts[:parent]).to_sym)
            Riemann::Babbler::Plugin.registered_plugins << klass
          end
        end
      end

      def run!
        plugin_names_to_run = AUTO_START + opts.plugins.to_hash.keys
        require_all_plugins
        started_plugins = []
        Riemann::Babbler::Plugin.registered_plugins.each do |klass|
          if plugin_names_to_run.include? name_to_underscore(klass.to_s)
            started_plugins << klass
          end
        end
        plugin_threads = started_plugins.map do |plugin|
          Thread.new {
            log :unknown, "Start plugin #{plugin}"
            plugin.new(sender).run!
          }
        end
        Signal.trap 'TERM' do
          plugin_threads.each(&:kill)
        end
        plugin_threads.each(&:join)
      end

    end
  end
end
