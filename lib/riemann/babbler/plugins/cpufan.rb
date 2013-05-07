class Riemann::Babbler::Cpufan < Riemann::Babbler

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
    { :service => plugin.service, :metric => shell(plugin.cmd).to_i, :description => "CPU Fan Speed" }
  end

end
