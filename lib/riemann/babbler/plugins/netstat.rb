class Riemann::Babbler::NetStat < Riemann::Babbler

  def init
    plugin.set_default(:service, 'netstat')
    plugin.set_default(:interval, 60)
    plugin.set_default(:port, 80)
    plugin.states.set_default(:warning, 300)
    plugin.states.set_default(:critical, 400)
  end

  def collect
    count = shell("netstat -nat4 | egrep -e ':#{plugin.port}\s'  | grep ESTA | wc -l").to_i
    {:service => "#{plugin.service} tcp #{plugin.port}", :metric => count, :description => "count established connects: #{count} to port #{plugin.port}"}
  end
end
