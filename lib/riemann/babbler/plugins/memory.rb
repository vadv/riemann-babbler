class Riemann::Babbler::Plugin::Memory < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'memory')
    plugin.states.set_default(:warning, 70)
    plugin.states.set_default(:critical, 85)
  end

  def collect
    m       = File.read('/proc/meminfo').split(/\n/).inject({}) { |info, line|
      x          = line.split(/:?\s+/)
      info[x[0]] = x[1].to_i
      info
    }
    free    = m['MemFree'].to_i * 1024
    cached  =m['Cached'].to_i * 1024
    buffers =m['Buffers'].to_i * 1024
    total   = m['MemTotal'].to_i * 1024
    used    = total - free
    free_bc = free + buffers + cached

    fraction      = 1 - (free_bc.to_f / total)
    swap_fraction = m['SwapTotal'] == 0 ? 0 : 1 - m['SwapFree'].to_f/m['SwapTotal']

    desc = "#{shell('ps -eo pmem,pid,cmd --sort -pmem | head -3').chomp}"
    [
        { :service => plugin.service + ' % free', :description => 'Memory usage, %', :metric => fraction.round(2) * 100 },
        { :service => plugin.service + ' % swap', :description => 'Swap usage, %', :metric => swap_fraction.round(2) * 100 },
        { :service => plugin.service + ' abs free', :description => "Memory free (kB)\n\n #{desc}", :metric => free, :state => 'ok' },
        { :service => plugin.service + ' abs total', :description => "Memory total (kB)\n\n #{desc}", :metric => total, :state => 'ok' },
        { :service => plugin.service + ' abs cached', :description => "Memory usage, cached (kB)\n\n #{desc}", :metric => cached, :state => 'ok' },
        { :service => plugin.service + ' abs buffers', :description => "Memory usage, buffers (kB)\n\n #{desc}", :metric => buffers, :state => 'ok' },
        { :service => plugin.service + ' abs used', :description => "Memory usage, used (kB)\n\n #{desc}", :metric => used, :state => 'ok' },
        { :service => plugin.service + ' abs free_bc', :description => "Memory usage with cache and buffers (kB)\n\n #{desc}", :metric => free_bc, :state => 'ok' }
    ]
  end

end
