class Riemann::Babbler::Twcli < Riemann::Babbler

  def init
    plugin.set_default(:service, 'twcli')
    plugin.set_default(:cmd, "/usr/sbin/tw_cli /$(/usr/sbin/tw_cli show | grep ^c | cut -f1 -d' ') show | egrep '^[upb]' | grep -v ' OK ' | grep -v ' VERIFYING ' | grep -v ' VERIFY-PAUSED ' | wc -l")
    plugin.states.set_default(:critical, 1)
    plugin.set_default(:interval, 300)
  end

  def run_plugin
    File.exists? '/usr/sbin/tw_cli'
  end

  def collect
    { 
      :service => plugin.service,
      :metric => shell(plugin.cmd).to_i,
      :description => "Hardware raid tw_cli status"
    }
  end

end