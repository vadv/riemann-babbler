class Riemann::Babbler::Net
  include Riemann::Babbler

  WORDS = ['rx bytes',
           'rx packets',
           'rx errs',
           'rx drop',
           'rx fifo',
           'rx frame',
           'rx compressed',
           'rx multicast',
           'tx bytes',
           'tx packets',
           'tx drops',
           'tx fifo',
           'tx colls',
           'tx carrier',
           'tx compressed']

  def plugin
    options.plugins.net
  end

  def init
    @old_status = Hash.new
  end

  def net
    f = File.read('/proc/net/dev')
    status = Hash.new
    @diff = Hash.new
    f.split("\n").each do |line|
      iface = line.split(":")[0].strip
      next unless line =~ /(\w*)\:\s*([\s\d]+)\s*/
      WORDS.map do |service|
        "#{plugin.service} #{iface} #{service}"
      end.zip(
        $2.split(/\s+/).map { |str| str.to_i }
      ).each do |service, value|
        status.merge!({service => value})
      end
    end
    status.each_key { |key| @diff.merge!({key => status[key] - @old_status[key]}) } unless @old_status.empty?
    @old_status = status
    @diff
  end

  def tick
    status = net
    status.each_key do |service|
      #next if status[service] == 0
      report({
        :service => service,
        :metric => status[service]
      })
    end
  end

end

Riemann::Babbler::Net.run
