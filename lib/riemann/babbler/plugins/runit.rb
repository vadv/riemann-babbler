class Riemann::Babbler::Runit < Riemann::Babbler

  def init
    plugin.set_default(:service, 'runit')
    plugin.set_default(:not_monit, [])
    plugin.set_default(:interval, 10)
  end

  def run_plugin
    Dir.exists? '/etc/service'
    @status_history = Array.new
  end

  def read_run_status
    status = Array.new
    Dir.glob('/etc/service/*').each do |srv|
      next if plugin.not_monit.include? srv
      human_srv = ' ' + srv.gsub(/\/etc\/service\//,"")
      if File.read( File.join(srv, 'supervise', 'stat') ).strip == 'run'
        @status_history.delete "human_srv"
        status << {:service => plugin.service + human_srv , :state => 'ok', :description => "runit service #{human_srv} running"}
      else
        status << {:service => plugin.service + human_srv , :state => 'critical', :description => "runit service #{human_srv} not running"} if @status_history.include? human_srv 
        @status_history << human_srv unless @status_history.include? human_srv
      end
    end
    status
  end

  def collect
    read_run_status
  end

end