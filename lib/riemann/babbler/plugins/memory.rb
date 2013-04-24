#encoding: utf-8

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

    fraction = 1 - (free_bc.to_f / total)
    swap_fraction = m['SwapTotal'] == 0 ? 0 : 1 - m['SwapFree'].to_f/m['SwapTotal']

    desc = "usage\n\n#{shell('ps -eo pcpu,pid,cmd --sort -pmem | head -10').chomp}"

    [
      { :service => plugin.service + " % free", :description => "Процент утилизации памяти", :metric => fraction.round(2) * 100 },
      { :service => plugin.service + " % swap", :description => "Процент утилизации своп", :metric => swap_fraction.round(2) * 100 },
      { :service => plugin.service + " abs free", :description => "Утилизация памяти (kB)\n\n #{desc}", :metric => free, :state => 'ok' },
      { :service => plugin.service + " abs total", :description => "Памяти всего (kB)\n\n #{desc}", :metric => total, :state => 'ok' },
      { :service => plugin.service + " abs cached", :description => "Утилизация памяти cached (kB)\n\n #{desc}",  :metric => cached, :state => 'ok' },
      { :service => plugin.service + " abs buffers", :description => "Утилизация памяти buffers (kB)\n\n #{desc}", :metric => buffers, :state => 'ok' },
      { :service => plugin.service + " abs used", :description => "Утилизация памяти used (kB)\n\n #{desc}", :metric => used , :state => 'ok' },
      { :service => plugin.service + " abs free_bc", :description => "Утилизация памяти с cache и buffers (kB)\n\n #{desc}", :metric => free_bc , :state => 'ok' }
    ]
  end

end
