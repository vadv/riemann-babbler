class Riemann::Babbler::Runit < Riemann::Babbler

  def init
    plugin.set_default(:service, 'runit')
    plugin.set_default(:not_monit, [])
    plugin.set_default(:interval, 60)
  end

  def run_plugin
    Dir.exists? '/etc/service'
    @status_history = Array.new
  end

  def read_run_status
    status = Array.new
    Dir.glob('/etc/service/*').each do |srv|
      next if plugin.not_monit.include? srv
      human_srv = ' ' + srv.gsub(/\/etc\/service\//, '')
      stat_file = File.join(srv, 'supervise', 'stat')
      next unless File.exists? stat_file
      if File.read( stat_file ).strip == 'run'
        @status_history.delete human_srv
        status << {:service => plugin.service + human_srv , :state => 'ok', :description => "runit service #{human_srv} running"}
      else
        if @status_history.include? human_srv 
          status << {:service => plugin.service + human_srv , :state => 'critical', :description => "runit service #{human_srv} not running"}
        end
        @status_history << human_srv unless @status_history.include? human_srv
      end
    end
    status
  end

  def collect
    read_run_status
  end

end
