require 'logger'

module Riemann
  module Babbler

    module Logging

      @levels  = { 'DEBUG' => 0, 'INFO' => 1, 'WARN' => 2, 'ERROR' => 3, 'FATAL' => 4 }
      @@logger = Logger.new(STDOUT) #todo: opts

      def log(log_level, message, method = nil)
        speaker = get_logger_speaker
        speaker = speaker + "##{method}" unless method.nil?
        @@logger.send(log_level.to_sym, " [#{speaker}] #{message}")
      end

      def set_logger_speaker(speaker)
        @logger_speaker = speaker
      end

      def get_logger_speaker
        if @logger_speaker.nil?
          self.class == Class ? "C: #{self.to_s}" : "I: #{self.class.to_s}"
        else
          @logger_speaker
        end
      end

      def self.included(base)
        base.extend(self)
      end

    end

  end
end