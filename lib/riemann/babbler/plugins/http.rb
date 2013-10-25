class Riemann::Babbler::Plugin::Http < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'http check')
    plugin.set_default(:interval, 60)
    plugin.states.set_default(:critical, 1)
    plugin.set_default(:http_code, 200)
    plugin.set_default(:http_method, 'GET')
    plugin.set_default(:connect_timeout, 5)
    plugin.set_default(:retry, 0)
    plugin.set_default(:retry_delay, 0)
    plugin.set_default(:max_time, 10)
    plugin.set_default(:insecure, false)

    plugin.set_default(:url, 'http://127.0.0.1:80')
  end

  def collect
    command = "curl -X#{plugin.http_method} -s"
    command += " --connect-timeout #{plugin.connect_timeout}"
    command += ' --insecure ' if plugin.insecure
    command += " -w '%{http_code}\\n'"
    command += " --retry #{plugin.retry} --retry-delay #{plugin.retry_delay}"
    command += " --max-time #{plugin.max_time} --fail"
    command += " #{plugin.url} -o /dev/null || echo 'mock exit status'"

    out = shell(command).to_i

    if out != plugin.http_code
      metric = 1
    else
      metric = 0
    end

    { :service => plugin.service, :metric => metric, :description => "http_code: #{out}" }
  end
end
