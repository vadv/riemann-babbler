class Riemann::Babbler::Plugin::CpuFan < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'cpufan')
    plugin.set_default(:cmd, '/usr/bin/sensors | grep "CPU FAN Speed:" | awk "{print $4}"')
    plugin.set_default(:interval, 60)
    plugin.states.set_default(:warning, 2000)
    plugin.states.set_default(:critical, 3000)
  end

  def run_plugin
    File.exists? '/usr/bin/sensors'
  end

  def collect
    metric = shell(plugin.cmd).to_i
    if metric == 0
      { :service => plugin.service, :state => 'ok', :description => 'CPU Fan Speed' }
    else
      { :service => plugin.service, :metric => metric, :description => 'CPU Fan Speed' }
    end
  end

end
