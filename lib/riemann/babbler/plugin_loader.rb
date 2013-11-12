require_relative 'plugin'

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
          'ntp',
          'exim4',
          'la',
          'mdadm',
          'mega_cli',
          'memory',
          'net',
          'runit',
          'tw_cli',
          'iptables',
          'errors_reporter',
          'responder_http',
          'responder_udp',
      ].freeze

      attr_accessor :load_plugin_names_from_config, :delete_from_autostart

      def initialize
        @load_plugin_names_from_config = Array.new
        @delete_from_autostart         = Array.new
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

      def require_parents
        # load parent
        opts.plugins.to_hash.each do |plugin_name, plugin_opts|
          next if plugin_opts.nil?
          next unless plugin_opts.kind_of?(Hash)
          if plugin_opts.has_key? :parent
            cmd = "class #{underscore_to_name plugin_name} < #{underscore_to_name plugin_opts[:parent]}; end;"
            cmd += "Riemann::Babbler::Plugin.registered_plugins << #{underscore_to_name plugin_name}"
            load_plugin_names_from_config << plugin_name
            eval(cmd)
          end
        end
      end

      def require_from_config
        # load array new fea
        new_opts = opts.to_hash
        opts.plugins.to_hash.each do |plugin_name, plugin_opts|
          next if plugin_opts.nil?
          next if plugin_name == :dirs
          next unless plugin_opts.kind_of?(Array)
          plugin_opts.each_with_index do |new_plugin_opts, index|
            parent_class    = underscore_to_name(plugin_name)
            new_plugin_name = "#{plugin_name}_#{index}"
            new_class       = "#{parent_class}_#{index}"
            cmd             = "class #{new_class} < #{parent_class}; end;"
            cmd             += "Riemann::Babbler::Plugin.registered_plugins << #{new_class}"
            eval(cmd)
            new_opts[:plugins][new_plugin_name.to_sym] = new_plugin_opts # set opts
            load_plugin_names_from_config << new_plugin_name.to_s
            delete_from_autostart << plugin_name.to_s
          end
          new_opts[:plugins].delete(plugin_name) # delete old if it array
        end
        opts_reset!(new_opts)
      end

      def require_all_plugins!
        Riemann::Babbler::Plugin.registered_plugins.clear
        all_available_plugins.each { |file| require file }
        log :debug, "Require plugins: #{Riemann::Babbler::Plugin.registered_plugins}"
        require_parents
        require_from_config
      end

      def plugin_to_start

        started_plugins = []

        plugin_names_to_run = AUTO_START +
            opts.plugins.to_hash.keys.map { |name| name.to_s }

        require_all_plugins!

        plugin_names_to_run = plugin_names_to_run +
            load_plugin_names_from_config.map { |name| name.to_s }

        plugin_names_to_run = (plugin_names_to_run - delete_from_autostart).uniq

        Riemann::Babbler::Plugin.registered_plugins.each do |klass|
          if plugin_names_to_run.include? name_to_underscore(klass.to_s)
            started_plugins << klass
          end
        end

        log :debug, "Return plugin to start: #{started_plugins}"
        started_plugins
      end

    end
  end
end
