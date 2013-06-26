class Riemann::Babbler::Net < Riemann::Babbler

  def collect
    f = File.read('/proc/net/dev')
    status = Array.new
    f.split("\n").each do |line|
      iface = line.split(':')[0].strip
      iface.gsub!(/\./, '_')
      next unless line =~ /(\w*)\:\s*([\s\d]+)\s*/
      status << { :service => "#{plugin.service} #{iface} bytes out", :metric => Net.out(iface, 'bytes'), :as_diff => true }
      status << { :service => "#{plugin.service} #{iface} bytes in", :metric => Net.in(iface, 'bytes'), :as_diff => true }
      status << { :service => "#{plugin.service} #{iface} bytes errors", :metric => Net.total(iface, 'errors'), :state => 'ok' }
    end
    status
  end

end
