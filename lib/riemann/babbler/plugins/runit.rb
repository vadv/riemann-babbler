class Riemann::Babbler::Runit < Riemann::Babbler

  def init
    plugin.set_default(:service, 'runit')
    plugin.set_default(:not_monit, [])
    plugin.set_default(:interval, 60)
  end

  def run_plugin
    Dir.exists? '/etc/service'
  end

  def read_run_status
    status = Array.new
    Dir.glob('/etc/service/*').each do |srv|
      next if plugin.not_monit.include? srv
      human_srv = ' ' + srv.gsub(/\/etc\/service\//,"")
      unless File.read( File.join(srv, 'supervise', 'stat') ).strip == 'run'
        status << {:service => plugin.service + human_srv , :state => 'critical', :description => "runit service #{human_srv} not running"}
      end
    end
    status
  end

  def collect
    read_run_status
  end

end
