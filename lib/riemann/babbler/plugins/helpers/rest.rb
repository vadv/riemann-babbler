#encoding: utf-8

require 'uri'
require 'net/http'

module Riemann
  module Babbler
    module Plugins
      module Helpers

        # http rest
        def rest_get(url)
          begin
            Timeout::timeout(plugin.timeout) do
              begin
                res = ::Net::HTTP.get_response(URI(url))
                raise ::Net::HTTPError unless res.kind_of?(::Net::HTTPSuccess)
                res.body
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
