#encoding: utf-8

require 'rest_client'

module Riemann
  module Babbler
    module Plugins
      module Helpers

        # http rest
        def rest_get(url)
          begin
            Timeout::timeout(plugin.timeout) do
              begin
                RestClient.get url
              rescue
                raise "Get from url: #{url} failed"
              end
            end
          rescue Timeout::Error
            raise "Get from url: #{url}, timeout error"
          end
        end

      end
    end
  end
end
