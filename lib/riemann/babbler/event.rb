module Riemann
  module Babbler
    class Event
      include Beefcake::Message
      optional :time, :int64, 1
      optional :state, :string,  2
      optional :service, :string, 3
      optional :host, :string, 4
      optional :description, :string, 5
      repeated :tags, :string, 7
      optional :ttl, :float, 8
      optional :metric_sint64, :sint64, 13
      optional :metric_d, :double, 14
      optional :metric_f, :float, 15

      def initialize(hash = nil)
        if hash
          super(hash)
          self.metric = hash[:metric] if hash[:metric]
        else
          super
        end
        @time ||= Time.now.to_i
      end

      def metric
        metric_d || metric_sint64 || metric_f
      end

      def metric=(m)
        if Integer === m and (-(2**63)...2**63) === m
          self.metric_sint64 = m
          self.metric_f = m.to_f
        else
          self.metric_d = m.to_f
          self.metric_f = m.to_f
        end
      end

    end
  end
end
