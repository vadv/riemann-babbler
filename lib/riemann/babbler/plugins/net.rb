class Riemann::Babbler::Plugin::Net < Riemann::Babbler::Plugin

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

  def init
    plugin.set_default(:service, 'net')
    plugin.set_default(:include_alias, false)
    plugin.set_default(:filter, ['rx bytes', 'rx errs', 'rx drop', 'tx bytes', 'tx errs', 'tx drop'])
  end

  def collect
    f      = File.read('/proc/net/dev')
    status = Array.new
    f.split("\n").each do |line|
      iface = line.split(':')[0].strip
      iface.gsub!(/\./, '_')
      next if (iface =~ /\./ && !plugin.include_alias)
      next unless line =~ /(\w*)\:\s*([\s\d]+)\s*/
      WORDS.map do |service|
        service
      end.zip(
          $2.split(/\s+/).map { |str| str.to_i }
      ).each do |service, value|
        next unless plugin.filter.include? service
        status << { :service => "#{plugin.service} #{iface} #{service}", :metric => value.to_f/plugin.interval, :as_diff => true }
      end
    end
    status
  end

end
