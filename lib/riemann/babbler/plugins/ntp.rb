require 'net/ntp'

class Riemann::Babbler::Plugin::Ntp < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'ntp')
    plugin.set_default(:host, 'pool.ntp.org')
    plugin.set_default(:server_timeout, 30)
    plugin.states.set_default(:warning, 5)
    plugin.states.set_default(:critical, 10)
  end

  def collect
    {
      :service     => plugin.service + " #{plugin.host}",
      :description => "Ntp lag with host #{plugin.host}",
      :metric      => (::Net::NTP.get(plugin.host, 'ntp', plugin.server_timeout).time.to_f - Time.now.to_f).abs
    }
  end

end
