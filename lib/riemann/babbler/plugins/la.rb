class Riemann::Babbler::Plugin::La < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'la')
    plugin.states.set_default(:warning, 4)
    plugin.states.set_default(:critical, 10)
  end

  def collect
    {
        :service     => plugin.service + ' la_1',
        :description => 'LA averaged over 1 minute',
        :metric      => File.read('/proc/loadavg').scan(/[\d\.]+/).first.to_f
    }
  end

end
