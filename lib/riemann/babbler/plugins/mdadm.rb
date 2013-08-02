class Riemann::Babbler::Mdadm < Riemann::Babbler

  def init
    plugin.set_default(:service, 'mdadm')
    plugin.set_default(:interval, 60)
    plugin.states.set_default(:critical, 1)
  end

  def run_plugin
    File.exists? '/proc/mdstat'
  end

  def collect 
    file = File.read('/proc/mdstat').split("\n")
    status = Array.new
    file.each_with_index do |line, index|
      next unless line.include? '_'
      device = file[index-1].split(':')[0].strip
      status << { :service => plugin.service + " #{device}", :metric => 1, :description => "mdadm failed device #{device}: #{get_failed_parts(device)}" }
    end
    status
  end

  def get_failed_parts (device)
    failed_parts = []
    Dir["/sys/block/#{device}/md/dev-*"].each do |p|
      state = File.read("#{p}/state").strip
      next unless state != "in_sync"
      p.gsub!(/.+\/dev-/,"")
      failed_parts << "#{p} (#{state})"
    end
    failed_parts.join(", ")
  end

end
