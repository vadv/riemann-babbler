class Riemann::Babbler::Diskstat < Riemann::Babbler

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

  def collect
    status = Array.new
    f = File.read('/proc/diskstats')
    state = f.split("\n").reject { |d| d =~ /(ram|loop| md| dm| sr)/ }.inject({}) do |s, line|
      if line =~ /^(?:\s+\d+){2}\s+([\w\d]+) (.*)$/
        dev = $1

        WORDS.map do |service|
          next unless plugin.filter.include?(service) #TODO hardcode
          "#{plugin.service} #{dev} #{service}"
        end.zip(
          $2.split(/\s+/).map { |str| str.to_i }
        ).each do |service, value|
          next if service.nil? #TODO hardcode
          status << { :service => service, :metric => value, :as_diff => true}
        end
      end 
    end
    status
  end

end
