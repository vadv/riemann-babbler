require 'json'

class Riemann::Babbler::Cloudrestreamerstatus < Riemann::Babbler

  def init
    plugin.set_default(:service, 'cloud restreamer clients')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://localhost/client/all')
  end

  def collect
    clients = 0
    json = JSON.parse rest_get(plugin.url)
    json.each do |worker|
      next unless worker.has_key? "processors"
      worker["processors"].each do |key, client_hash|
        next unless client_hash.has_key? "clients"
        client_hash["clients"].each {|key| clients += 1}
      end
    end
    {:service => plugin.service, :description => "Cloud restreamer clients in #{plugin.url}", :metric => clients, :state => 'ok' }
  end

end