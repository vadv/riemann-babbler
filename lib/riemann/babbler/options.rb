require 'configatron'

module Riemann
  module Babbler

    module Options

      @@configatron = configatron

      def opts
        @@configatron
      end

      #@return
      def merge_config(file)
        config_from_file = if File.exist?(file)
                             YAML.load_file(file).to_hash
                           else
                             log :error, "Can't load config file #{file}"
                             Hash.new
                           end
        config_default   = opts.to_hash
        result_config    = config_default.deep_merge(config_from_file)
        opts.configure_from_hash(result_config)
      end

      # return string tw_cli_3
      def name_to_underscore(name = 'Riemann::Babbler::Plugin::TwCli_3')
        name.split('::').last.gsub(/(\p{Lower})(\p{Upper})/, "\\1_\\2").downcase
      end

      # return string Riemann::Babbler::Plugin::TwCli_3
      def underscore_to_name(name = 'tw_cli_3', parent = 'Riemann::Babbler::Plugin')
        parent + '::'  + name.to_s.split('_').map { |part|
          if part.to_i != 0
            "_#{part}"
          else
            part.capitalize
          end
        }.join('')
      end

      def self.included(base)
        Configatron.log.level = Logger::FATAL
        base.extend(self)
      end

    end

  end
end
