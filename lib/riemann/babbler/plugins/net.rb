class Riemann::Babbler::Net < Riemann::Babbler

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

  def collect
    f = File.read('/proc/net/dev')
    status = Array.new
    f.split("\n").each do |line|
      iface = line.split(":")[0].strip
      iface.gsub!(/\./,"_")
      next unless line =~ /(\w*)\:\s*([\s\d]+)\s*/
      WORDS.map do |service|
        "#{plugin.service} #{iface} #{service}"
      end.zip(
        $2.split(/\s+/).map { |str| str.to_i }
      ).each do |service, value|
        status << { :service => service, :metric => value, :as_diff => true}
      end
    end
    status
  end

end
