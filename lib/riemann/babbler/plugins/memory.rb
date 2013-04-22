class Riemann::Babbler::Memory < Riemann::Babbler

  def collect
    m = File.read('/proc/meminfo').split(/\n/).inject({}) { |info, line|
      x = line.split(/:?\s+/)
      info[x[0]] = x[1].to_i
      info
    }
    free = m['MemFree'].to_i * 1024
    cached =m['Cached'].to_i * 1024
    buffers =m['Buffers'].to_i * 1024
    total = m['MemTotal'].to_i * 1024
    used = total - free
    free_bc = free + buffers + cached

    fraction = 1 - (free.to_f / total)
    swap_fraction = m['SwapTotal'] == 0 ? 0 : 1 - m['SwapFree'].to_f/m['SwapTotal']

    desc = "usage\n\n#{shell('ps -eo pmem,pid,cmd | sort -nrb -k1 | head -10').chomp}"

    [
      { :service => plugin.service + " % free", :metric => fraction.round(2) * 100 },
      { :service => plugin.service + " % swap", :metric => swap_fraction.round(2) * 100 },
      { :service => plugin.service + " abs free", :metric => free, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs total", :metric => total, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs cached", :metric => cached, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs buffers", :metric => buffers, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs used", :metric => used , :state => 'ok', :description => desc },
      { :service => plugin.service + " abs free_bc", :metric => free_bc , :state => 'ok', :description => desc }
    ]
  end

end
