require 'json'

class Riemann::Babbler::Nvidia < Riemann::Babbler

  def init
    plugin.set_default(:service, 'nvidia')
    plugin.set_default(:cmd, '/usr/bin/nvidia-info -j')
    plugin.set_default(:interval, 60)
    plugin.states.set_default(:warning, 70)
    plugin.states.set_default(:critical, 90)
  end

  def run_plugin
    File.exists? '/usr/bin/nvidia-info'
  end


  def collect
    hash = JSON.parse shell(plugin.cmd)
    array = Array.new
    hash.each do |info| 
      array << { :service => plugin.service + ' memory usage', :metric => (info['memory_usage']['free'].to_f/info['memory_usage']['total'].to_i) * 100, :description => "GPU memory usage in %" }
    end  
    array
  end

end
