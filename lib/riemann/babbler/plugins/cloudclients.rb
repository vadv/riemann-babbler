require 'json'

class Riemann::Babbler::CloudClients < Riemann::Babbler

  def init
    plugin.set_default(:service, 'cloud clients')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://localhost/client/all')
  end

  def collect

    json = JSON.parse rest_get(plugin.url)
    clients = 0

    json.each do |client|
      client["state"] == "ESTABLISHED" ? clients += 1
    end

    [
      {:service => plugin.service + " ESTABLISHED state", :description => "online clients in #{plugin.url}", :metric => clients, :state => 'ok' }
    ]
  end

end
