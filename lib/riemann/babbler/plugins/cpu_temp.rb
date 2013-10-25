class Riemann::Babbler::Plugin::CpuTemp < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'cputemp')
    plugin.set_default(:interval, 60)
    plugin.set_default(:cmd, '/usr/bin/sensors | grep "CPU Temperature:" | awk "{print $3}" | cut -c2-3')
    plugin.states.set_default(:warning, 60)
    plugin.states.set_default(:critical, 80)
  end

  def run_plugin
    File.exists? '/usr/bin/sensors'
  end

  def collect
    { :service => plugin.service, :metric => shell(plugin.cmd).to_i, :description => 'CPU Temperature' }
  end

end

