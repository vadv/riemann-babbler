class Riemann::Babbler::NetStat < Riemann::Babbler

  def init
    plugin.set_default(:service, 'netstat')
    plugin.set_default(:interval, 5)
    plugin.set_default(:ports, [80, 3994])
    plugin.states.set_default(:warning, nil)
    plugin.states.set_default(:critical, nil)
  end

  def get_conn_count
    filter = nil
    plugin.ports.each do |port|
      if filter == nil
        filter = "\\( src *:#{port}"
      else
        filter += " or src *:#{port}"
      end
    end
    filter += " \\) and not dst 127.0.0.1:*"
    cmd = "ss -t -4 -n state established " + filter + " | wc -l"
    shell(cmd).to_i - 1
  end

  def collect
    count = get_conn_count()
    {
      :service => "#{plugin.service} tcp #{plugin.ports.join(', ')}",
      :metric => count, 
      :description => "count established connects: #{count} to ports #{plugin.ports.join(', ')}"
    }
  end
end
