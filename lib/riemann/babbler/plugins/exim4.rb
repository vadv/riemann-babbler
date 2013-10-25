class Riemann::Babbler::Plugin::Exim4 < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'exim4')
    plugin.set_default(:cmd, '/usr/sbin/exim -bpc')
    plugin.set_default(:interval, 60)
    plugin.states.set_default(:warning, 5)
    plugin.states.set_default(:critical, 20)
  end

  def run_plugin
    File.exists? '/usr/sbin/exim'
  end

  def collect
    { :service => plugin.service, :metric => shell(plugin.cmd).to_i, :description => 'Exim4: count frozen mails' }
  end

end
