require 'json'

class Riemann::Babbler::Mpeg2lander < Riemann::Babbler

  def init
    plugin.set_default(:service, 'mpeg2lander')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://localhost/status')
    plugin.states.set_default(:critical, 10)
  end

  def collect
    array = Array.new
    JSON.parse( rest_get( plugin.url ) )['streams'].each do |stream|
      stream['programs'].each do |programm|
        next unless programm['time_tracker']
        next unless programm['time_tracker']['current_time']
        timing = programm['time_tracker']['current_time'].split('diff')[1].to_i
        array << { :service => plugin.service + " status #{programm['name']}", :metric => timing.to_i, :description => "Mpeg2lander timming name #{programm['name']}" }
      end # end programm
    end # end stream
    array
  end

end
