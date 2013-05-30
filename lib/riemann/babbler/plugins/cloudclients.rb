require 'json'

class Riemann::Babbler::Cloudclients < Riemann::Babbler

  def init
    plugin.set_default(:service, 'cloud clients')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://localhost/client/all')
  end

  def collect
    clients = 0
    json = JSON.parse rest_get(plugin.url)
    json.each { |client| clients += 1 if client[1]["state"] == "ESTABLISHED" }
    {:service => plugin.service + " established", :description => "online clients in #{plugin.url}", :metric => clients, :state => 'ok' }
  end

end
