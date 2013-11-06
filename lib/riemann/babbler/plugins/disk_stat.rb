class Riemann::Babbler::Plugin::DiskStat < Riemann::Babbler::Plugin

  WORDS = [
      'reads reqs',
      'reads merged',
      'reads sector',
      'reads time',
      'writes reqs',
      'writes merged',
      'writes sector',
      'writes time',
      'io reqs',
      'io time',
      'io weighted'
  ]

  def init
    plugin.set_default(:service, 'diskstat')
    plugin.set_default(:interval, 60)
    plugin.set_default(:filter, ['reads reqs', 'writes reqs'])
  end

  def run_plugin
    File.exists? '/proc/diskstats'
  end

  def collect
    status = Array.new
    f      = File.read('/proc/diskstats')
    f.split("\n").reject { |d| d =~ /(ram|loop)/ }.inject({}) do |_, line|
      if line =~ /^(?:\s+\d+){2}\s+([\w\d]+) (.*)$/
        dev    = $1
        values = $2.split(/\s+/).map { |str| str.to_i }
        # пропускаем неинтересные девайсы
        # которые закнчиваются на число, но при этом не пропускаем xvd
        next if !!(dev.match /\d+$/ || !(dev.match =~ /^xvd/))
        # читаем все фильтры
        plugin.filter.each do |filter|
          status << { :service => "#{plugin.service} #{dev} #{filter}", :metric => values[WORDS.index(filter)].to_f/plugin.interval, :as_diff => true }
        end
        # добавляем iops
        iops = values[WORDS.index('reads reqs')].to_i + values[WORDS.index('writes reqs')].to_i
        status << { :service => "#{plugin.service} #{dev} iops", :metric => iops.to_f/plugin.interval, :as_diff => true }
      end
    end
    status
  end

end
