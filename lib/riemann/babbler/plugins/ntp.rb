require 'net/ntp'

class Riemann::Babbler::Plugin::Ntp < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'ntp')
    plugin.set_default(:host, 'pool.ntp.org')
    plugin.states.set_default(:warning, 5)
    plugin.states.set_default(:critical, 10)
  end

  def diff
    Net::NTP.get(plugin.host, 'ntp', 5).time.to_i - Time.now.to_i
  end

  def collect
    {
      :service     => plugin.service + " #{plugin.host}",
      :description => "Ntp lag with host #{plugin.host}",
      :metric      => (::Net::NTP.get(plugin.host, 'ntp', 5).time.to_i - unixnow).abs
    }
  end

end
