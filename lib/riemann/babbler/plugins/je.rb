require 'json'

class Riemann::Babbler::Je < Riemann::Babbler

  def init
    plugin.set_default(:service, 'je')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://localhost/status')
    plugin.states.set_default(:critical, 10)
  end

  def collect
    array = Array.new
    JSON.parse( rest_get( plugin.url ) ).each do |channel|
      timing = (unixnow - channel['moment'].to_i).abs
      sid = channel['sid']
      array << { :service => plugin.service + " status #{sid}", :metric => timing.to_i, :description => "Je timming sid #{sid}, in sec." }
    end
    array
  end
  
end
