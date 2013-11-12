#encoding: utf-8

module Riemann
  module Babbler
    module Plugins
      module Helpers

        RIEMANN_RESERVED_FIELDS = [
          :time,
          :state,
          :service,
          :host,
          :description,
          :metric,
          :tags,
          :ttl
        ]

        def event_from_hash(hash=nil)
          if hash
            new_hash = Hash.new
            RIEMANN_RESERVED_FIELDS.each do |key|
              new_hash[key] = hash[key] || hash[key.to_s]
            end
            new_hash
          else
            Hash.new
          end
        end

        def event_from_json(str)
          event_from_hash(JSON.parse(str))
        end

      end
    end
  end
end
