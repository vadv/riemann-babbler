#encoding: utf-8

require 'open-uri'

module Riemann
  module Babbler
    module Plugins
      module Helpers

        # http rest
        def rest_get(url)
          begin
            Timeout::timeout(plugin.timeout) do
              begin
                uri = URI(url)
                if uri.userinfo
                  open("#{uri.scheme}://#{uri.hostname}:#{uri.port}#{uri.request_uri}", 
                    :http_basic_authentication => [uri.user, uri.password]).read
                else
                  open(url).read
                end
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
