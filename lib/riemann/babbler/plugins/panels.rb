require 'json'

class Riemann::Babbler::Panels < Riemann::Babbler

  def init
    plugin.set_default(:service, 'panels')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://localhost/panel.json')
    plugin.states.set_default(:critical, 60)
  end

  def collect

    json = JSON.parse rest_get(plugin.url)
    good, bad = 0, 0

    json["panels"].each do |panel|
      panel["status"] == "offline" ? bad += 1 : good += 1
    end

    [
      {:service => plugin.service + " online", :description => "online panels in #{plugin.url}", :metric => good, :state => 'ok' },
      {:service => plugin.service + " all", :description => "all panels in #{plugin.url}", :metric => bad + good, :state => 'ok' }
    ]
  end

end
