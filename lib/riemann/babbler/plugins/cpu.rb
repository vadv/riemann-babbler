class Riemann::Babbler::Cpu < Riemann::Babbler

  def desc
    "usage\n\n#{shell('ps -eo pcpu,pid,cmd | sort -nrb -k1 | head -10').chomp}"
  end

  def init
    @old_cpu = Hash.new
  end

  def collect
    array = Array.new
    description = desc
    File.read('/proc/stat').split("\n").each do |cpu_line|

      # проверяем есть строчка /cpu\d+/ или /cpu / и сграбливаем это в переменную
      cpu_number = cpu_line.scan(/cpu(\d+|\s)\s+/)
      next if cpu_number.empty?
      cpu_number = cpu_number[0][0] == " " ? "_total" : cpu_number[0][0] 

      # работаем со строкой
      cpu_line[/cpu(\d+|\s)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/]
      _, u2, n2, s2, i2 = [$1, $2, $3, $4, $5].map { |e| e.to_i }

      unless @old_cpu[cpu_number].nil?
        u1, n1, s1, i1 = @old_cpu[cpu_number]
        used = (u2+n2+s2) - (u1+n1+s1)
        total = used + i2-i1
        fraction = used.to_f / total
      end

      @old_cpu[cpu_number] = [u2, n2, s2, i2]
      array << { :service => plugin.service + " cpu#{cpu_number}", :metric => fraction, :description => description } if fraction
    end
    array
  end

end
