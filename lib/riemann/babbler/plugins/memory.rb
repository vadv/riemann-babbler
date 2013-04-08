class Riemann::Babbler::Memory < Riemann::Babbler

  def memory
    m = File.read('/proc/meminfo').split(/\n/).inject({}) { |info, line|
      x = line.split(/:?\s+/)
      info[x[0]] = x[1].to_i
      info
    }
    free = m['MemFree'].to_i + m['Buffers'].to_i + m['Cached'].to_i
    total = m['MemTotal'].to_i
    fraction = 1 - (free.to_f / total)
    return {:free => (free.to_f/1024), :fraction => fraction, :total => (total.to_f/1024)}
  end

  def tick
    current_state = memory
    # соотношение свободной/занятой
    report({
      :service => plugin.service,
      :state => state(current_state[:fraction]),
      :metric => current_state[:fraction]
    })
    # постим сообщение о свобоной памяти
    report({
      :service => plugin.service + " free",
      :metric => current_state[:free]
    }) if plugin.report_free
    # постим сообение о том сколько у нас вообще памяти
    report({
      :service => plugin.service + " total",
      :metric => current_state[:total]
    }) if plugin.report_total
  end

end
