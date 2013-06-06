class Riemann::Babbler::Cuboxtemp < Riemann::Babbler

  def init
    plugin.set_default(:service, 'cuboxtemp')
    plugin.set_default(:interval, 60)
    plugin.set_default(:cmd, "sensors | grep 'T-junction' | awk '{print $2}'")
    plugin.states.set_default(:warning, 90)
    plugin.states.set_default(:critical, 100)
  end

  def run_plugin
    File.exists? '/usr/bin/sensors'
  end

  def collect
    { :service => plugin.service, :metric => shell(plugin.cmd).to_i, :description => "Cubox temperature" }
  end

end

