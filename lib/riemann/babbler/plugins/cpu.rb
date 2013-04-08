class Riemann::Babbler::Cpu < Riemann::Babbler

  def collect
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
    {:service => plugin.service, :metric => fraction}
  end

end
