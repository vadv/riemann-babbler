class Riemann::Babbler::Memory < Riemann::Babbler

  def collect
    m = File.read('/proc/meminfo').split(/\n/).inject({}) { |info, line|
      x = line.split(/:?\s+/)
      info[x[0]] = x[1].to_i
      info
    }
    free = m['MemFree'].to_i + m['Buffers'].to_i + m['Cached'].to_i
    total = m['MemTotal'].to_i
    fraction = 1 - (free.to_f / total)

    [
      { :service => plugin.service, :metric => fraction },
      { :service => plugin.service + " free", :metric => free.to_f },
      { :service => plugin.service + " total", :metric => total.to_f}
    ]
  end

end
