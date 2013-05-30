require 'json'

class Riemann::Babbler::Selfupdate < Riemann::Babbler

  def init
    plugin.set_default(:service, 'self update')
    plugin.set_default(:file, '/var/run/status')
  end

  def collect
    json = JSON.parse File.read(plugin.url)
    if json["status"] == "ok"
      {:service => plugin.service, :description => "Self update status in #{plugin.file}, state: OK", :metric => 1, :state => 'ok' }
    else
      {:service => plugin.service, :description => "Self update status in #{plugin.file}, state: #{state['status']}, code: #{state['code']}", :metric => 0, :state => 'critical' }
    end
  end

end
