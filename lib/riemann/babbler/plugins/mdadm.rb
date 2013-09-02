class Riemann::Babbler::Mdadm < Riemann::Babbler

  def init
    plugin.set_default(:service, 'mdadm')
    plugin.set_default(:interval, 60)
    plugin.states.set_default(:critical, 1)
  end

  def run_plugin
    File.exists? '/proc/mdstat'
  end

  def mdadm_status_well?(text)
    text = text.gsub('[','').gsub(']','')
    text.gsub(/U/,'').empty?
  end

  def collect 
    file = File.read('/proc/mdstat').split("\n")
    status = Array.new
    file.each_with_index do |line, index|
      next unless line.include?('blocks')

      device = file[index-1].split(':')[0].strip

      mdstatus = line.split(" ").last
      next if mdadm_status_well?(mdstatus) # пропускаем все збс
      if mdstatus == plugin.states.send(device).to_s # пропускаем если стейт зафикисирован в конфиге
        status << { :service => plugin.service + " #{device}", :metric => 1, :state => 'ok', :description => "mdadm failed device #{device}, but disabled in config" }
        next
      end

      status << { :service => plugin.service + " #{device}", :metric => 1, :description => "mdadm failed device #{device}: #{get_failed_parts(device)}" }
    end
    status
  end

  def get_failed_parts (device)
    begin
      failed_parts = []
      Dir["/sys/block/#{device}/md/dev-*"].each do |p|
        state = File.read("#{p}/state").strip
        next unless state != "in_sync"
        p.gsub!(/.+\/dev-/,"")
        failed_parts << "#{p} (#{state})"
      end
      failed_parts.join(", ")
    rescue
      nil
    end
  end

end
