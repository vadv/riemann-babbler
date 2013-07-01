class Riemann::Babbler::MegaCli < Riemann::Babbler

  def init
    plugin.set_default(:service, 'megacli')
    plugin.set_default(:cmd, 'megacli -AdpAllInfo -aAll -NoLog | awk -F": " \'/Virtual Drives/ { getline; print $2; }\'')
    plugin.set_default(:interval, 60)
    plugin.states.set_default(:critical, 1)
  end

  def run_plugin
    File.exists? '/usr/bin/megacli'
  end

  def collect
    {:service => plugin.service, :metric => shell(plugin.cmd).to_i, :description => 'MegaCli status'}
  end

end

