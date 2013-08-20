class Riemann::Babbler::Runit < Riemann::Babbler

  def init
    plugin.set_default(:service, 'runit')
    plugin.set_default(:not_monit, ['riemann-client'])
    plugin.set_default(:uptime, 10)
    plugin.set_default(:interval, 60)
  end

  def run_plugin
    Dir.exists? '/etc/service'
  end

  # service uptime
  def uptime(service)
    pid_file = File.join(service, 'supervise', 'pid')
    return 0 unless File.exist?(pid_file)
    Time.now.to_i - File.mtime(pid_file).to_i
  end

  def read_run_status
    status = Array.new
    Dir.glob('/etc/service/*').each do |srv|
      human_srv = srv.gsub(/\/etc\/service\//, '')
      next if plugin.not_monit.include? human_srv
      stat_file = File.join(srv, 'supervise', 'stat')
      next unless File.exists? stat_file
      srv_uptime = uptime(srv)
      if (File.read( stat_file ).strip == 'run') && (srv_uptime > plugin.uptime)
        status << {:service => plugin.service + ' ' + human_srv , :state => 'ok', :description => "runit service #{human_srv} running", :metric => srv_uptime}
      else
        status << {:service => plugin.service + ' ' + human_srv , :state => 'critical', :description => "runit service #{human_srv} not running", :metric => srv_uptime}
      end
    end
    status
  end

  def collect
    read_run_status
  end

end
