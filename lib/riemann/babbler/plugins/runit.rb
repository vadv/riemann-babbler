class Riemann::Babbler::Plugin::Runit < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'runit')
    plugin.set_default(:not_monit, %w(riemann-client))
    plugin.set_default(:interval, 60)
    @status_history = Array.new
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

  def runned?(service)
    stat_file = File.join(service, 'supervise', 'stat')
    return false unless File.exists?(stat_file)
    File.read(stat_file).strip == 'run'
  end

  def human_srv(service)
    service.gsub(/\/etc\/service\//, '')
  end

  def not_monit?(service)
    plugin.not_monit.include? human_srv(service)
  end

  def read_run_status
    status = Array.new
    Dir.glob('/etc/service/*').each do |srv|

      next if not_monit?(srv)
      srv_uptime = uptime(srv)
      srv_runned = runned?(srv)
      srv_name   = human_srv(srv)

      # сервис запущен и работает дольше чем мы приходили к нему в прошлый раз
      if srv_runned && srv_uptime > plugin.interval
        @status_history.delete(srv_name)
        status << { :service => plugin.service + ' ' + srv_name, :state => 'ok', :description => "runit service #{srv_name} running" }
      else
        # сервис запущен но работает подозрительно мало, но последний раз замечен не был
        if srv_uptime < plugin.interval && srv_runned && !@status_history.include?(srv_name)
          # просто его запоминаем
          @status_history << srv_name
        else
          # во всех остальных случаях сообщаем о проблеме
          status << { :service => plugin.service + ' ' + srv_name, :state => 'critical', :description => "runit service #{srv_name} not running", :metric => srv_uptime }
        end
      end

    end
    status
  end

  def collect
    read_run_status
  end

end
