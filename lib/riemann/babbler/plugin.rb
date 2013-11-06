#encoding: utf-8

require 'riemann/babbler/plugins/helpers/init'

module Riemann
  module Babbler

    module State
      OK       = 'ok'
      WARNING  = 'warning'
      CRITICAL = 'critical'
    end

    class Plugin

      include Riemann::Babbler::Logging
      include Riemann::Babbler::Errors
      include Riemann::Babbler::Options
      include Riemann::Babbler::Plugins::Helpers

      def self.registered_plugins
        @plugins ||= []
      end

      def self.inherited(klass)
        registered_plugins << klass
      end

      attr_reader :riemann, :plugin_name, :plugin, :errors

      def initialize(riemann)
        @riemann                = riemann
        @storage                = Hash.new
        @storage['last_state']  = Hash.new
        @storage['last_metric'] = Hash.new
        @plugin_name            = name_to_underscore(self.class.name)
        @plugin                 = opts.plugins.send(plugin_name)
        @errors                 = opts.errors.send(plugin_name)
        set_default
        init
      end

      def set_default
        plugin.set_default(:interval, opts.riemann.interval)
        plugin.timeout        = (plugin.interval * 2).to_f/3
        errors.last_error     = nil
        errors.last_error_at  = nil
        errors.has_last_error = false
        errors.reported       = true
        plugin_no_error!
        errors.count = 0
      end

      def init
        # nothing to do
      end

      def run_plugin
        if plugin.run.nil?
          true
        else
          plugin.run ? true : false
        end
      end

      def tick
        posted_array = collect
        posted_array = posted_array.class == Array ? posted_array : [posted_array]
        posted_array.uniq.each { |event| report event }
      end

      def report(event)
        report_with_diff(event) and return if event[:as_diff]
        event[:metric] = event[:metric].round(2) if event[:metric].kind_of? Float
        event[:state] = get_state(event)
        riemann << event if not_minimize_sent_event(event)
        set_last_event(event)
      end


      ### Helper for reports ###

      def report_with_diff(event)
        current_metric = event[:metric]
        old_metric     = @storage['last_metric'][event[:service]]
        if old_metric && ((current_metric + old_metric) < (2**64.to_f/plugin.inteval))
          event[:metric] = current_metric - old_metric
          event.delete(:as_diff)
          report(event)
        end
        @storage['last_metric'][event[:service]] = current_metric
      end

      #@return state
      def get_state(event)
        return event[:state] if event[:state]
        return event[:state] if event[:metric].nil?
        metric   = event[:metric].to_f
        warning  = plugin.states.warning.nil? ? nil : plugin.states.warning
        critical = plugin.states.critical.nil? ? nil : plugin.states.critical
        return State::OK if (warning || critical).nil?
        if warning && critical
          return case
                   when metric.between?(warning, critical)
                     State::WARNING
                   when metric > warning
                     State::CRITICAL
                   else
                     State::OK
                 end
        end
        if warning
          return (metric >= warning) ? State::WARNING : State::OK
        end
        if critical
          return (metric >= critical) ? State::CRITICAL : State::OK
        end
      end

      #@return true if event may be sended
      def not_minimize_sent_event(event)
        return true if !opts.riemann.minimize_event_count # нет задачи минизировать
        return true if event[:metric]                     # если есть метрика - надо отослать graphite
        return true if event[:state] != State::OK         # все предупреждения отсылаем
        return true if @storage['last_state'][event[:service]] != State::OK
        log :debug, "Skip send event #{event}"
        false
      end

      def set_last_event(event)
        # тут пока только last_state
        @storage['last_state'][event[:service]] = event[:state] if opts.riemann.minimize_event_count
      end

      ### Errors ###
      def plugin_error!(msg)
        errors.count += 1
        log :error, "#{plugin.service} error num #{errors.count}:\n #{msg}"
        errors.has_last_error = true
        errors.reported       = false
        errors.last_error_at  = Time.now
        errors.last_error     = "#{msg}"
      end

      def plugin_no_error!
        if errors.has_last_error
          log :error, "#{plugin.service} error num #{errors.count} fixed"
          errors.has_last_error = false
        end
      end

      # Main method
      def run!
        return 0 unless run_plugin
        t0 = Time.now
        loop do

          begin
            Timeout::timeout(plugin.interval) { tick }
          rescue TimeoutError
            plugin_error!('Timeout plugin execution')
          rescue => e
            plugin_error!("Plugin '#{plugin_name}' has a error.\n #{e.class}: #{e}\n #{e.backtrace.join("\n")}")
          else
            plugin_no_error!
          end

          sleep(plugin.interval - ((Time.now - t0) % plugin.interval))
        end

      end

    end

  end
end
