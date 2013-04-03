class Riemann::Babbler::Cpu
  include Riemann::Babbler

  def plugin
    options.plugins.cpu
  end

  def cpu
    cpu = File.read('/proc/stat')
    cpu[/cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/]
    u2, n2, s2, i2 = [$1, $2, $3, $4].map { |e| e.to_i }

    if @old_cpu
      u1, n1, s1, i1 = @old_cpu
      used = (u2+n2+s2) - (u1+n1+s1)
      total = used + i2-i1
      fraction = used.to_f / total
    end

    @old_cpu = [u2, n2, s2, i2]
    fraction
  end

  def tick
    current_state = cpu
    report({
      :service => plugin.service,
      :state => state(current_state),
      :metric => current_state
    })
  end

end

Riemann::Babbler::Cpu.run
