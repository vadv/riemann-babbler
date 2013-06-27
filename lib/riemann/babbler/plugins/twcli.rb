class Riemann::Babbler::Twcli < Riemann::Babbler

  def init
    plugin.set_default(:service, 'tw_cli raid status')
    plugin.set_default(:cmd, "tw_cli /$(tw_cli show | grep ^c | cut -f1 -d' ') show | egrep '^[upb]' | grep -v ' OK ' | wc -l")
    plugin.states.set_default(:critical, 1)
    plugin.set_default(:interval, 300)
  end

  def run
    File.exists? '/usr/sbin/tw_cli'
  end

  def collect
    {
      :service => plugin.service,
      :metric => shell(plugin.cmd).to_i,
      :description => "Hardware raid status"
    }
  end

end