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
      { :service => plugin.service + " abs free", :description => "Утилизация памяти (kB)", :metric => free, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs total", :description => "Памяти всего (kB)", :metric => total, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs cached", :description => "Утилизация памяти cached (kB)",  :metric => cached, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs buffers", :description => "Утилизация памяти buffers (kB)", :metric => buffers, :state => 'ok', :description => desc },
      { :service => plugin.service + " abs used", :description => "Утилизация памяти used (kB)", :metric => used , :state => 'ok', :description => desc },
      { :service => plugin.service + " abs free_bc", :description => "Утилизация памяти с cache и buffers (kB)", :metric => free_bc , :state => 'ok', :description => desc }
    ]
  end

end
