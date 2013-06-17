require 'json'

class Riemann::Babbler::Sdigrabber < Riemann::Babbler

  def init
    plugin.set_default(:service, 'sdigrabber')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://localhost/status')
    plugin.states.set_default(:critical, 10)
  end

  def collect
    array = Array.new
    JSON.parse( rest_get( plugin.url ) ).each do |box|
      box['processors'].each do |processor, processor_options|
        next unless processor =~ /Proc\s+encoder/
        next unless processor_options['setup']['last-unit-pts']
        timing = unixnow - processor_options['setup']['last-unit-pts'].to_i
        cid = processor_options['setup']['cid']
        array << { :service => plugin.service + " status #{cid}", :metric => timing.to_i, :description => "Sdigrabber timming cid #{cid}" }
      end
    end
    array
  end
  
end
