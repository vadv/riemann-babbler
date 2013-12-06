class Riemann::Babbler::Plugin::Iptables < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'iptables')
    plugin.set_default(:rules_file, '/etc/network/iptables')
    plugin.set_default(:interval, 60)
  end

  def run_plugin
    File.exists? plugin.rules_file
  end

  def delete_counters(str)
    str.gsub(/\[\d+\:\d+\]/, '').strip
  end

  def collect

    current_rules = shell('iptables-save').split("\n").map do |x|
      x[0] == "#" ? nil : delete_counters(x) # delete counters and comments
    end.compact.sort.join("\n")

    saved_rules = File.read(plugin.rules_file).split("\n").map do |x|
      x[0] == "#" ? nil : delete_counters(x) # delete counters and comments
    end.compact.sort.join("\n")

    status =  current_rules == saved_rules ? 'ok' : 'critical'
    {
        :service => "#{plugin.service} #{plugin.rules_file}",
        :state => status, #  status 'ok' will be minimized
        :description => "#{plugin.service} rules different between file: #{plugin.rules_file} and iptables-save"
    }

  end

end
