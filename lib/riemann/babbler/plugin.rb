module Riemann
  module Babbler

    require 'riemann/client'

    def self.included(base)
      base.instance_eval do
        def run
          new.run
        end

      end
    end

    def initialize
      @configatron = $configatron
      super
    end

    def log
      @logger ||= $logger
    end

    def options
      @configatron
    end
    alias :opts :options

    def report(event)
      event[:tags] = options.riemann.tags unless options.riemann.tags.nil?
      event[:host] =  host
      log.debug "Report status: #{event.inspect}"
      riemann << event
    end

    def host
      hostname = `hostname`.chomp.downcase
      hostname += options.riemann.suffix unless options.riemann.suffix.nil?
      hostname
    end

    def riemann
      @riemann ||= Riemann::Client.new(
        :host => options.riemann.host,
        :port => options.riemann.port
      )
    end
    alias :r :riemann

    def run
      t0 = Time.now
      loop do
        begin
          tick
        rescue => e
          $stderr.puts "#{e.class} #{e}\n#{e.backtrace.join "\n"}"
        end

        # Sleep.
        sleep(plugin.interval - ((Time.now - t0) % plugin.interval))
      end
    end

    # Переодически вызываемое действие
    def tick
    end

    # Доступ к конфигу определенного плагина
    def plugin
    end

    # описание статуса
    def state(my_state)
      case
      when my_state.between?(plugin.states.warning, plugin.states.critical)
        'warning'
      when my_state > plugin.states.warning
        'critical'
      else
        'ok'
      end
    end

  end
end
