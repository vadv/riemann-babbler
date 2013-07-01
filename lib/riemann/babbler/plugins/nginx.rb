class Riemann::Babbler::Nginx < Riemann::Babbler

    NGINX_STATUS_1 = %W(accepts handled requests)

    NGINX_STATUS_2 = %W(reading writing waiting)

  def init
    plugin.set_default(:service, 'nginx')
    plugin.set_default(:status_file, '/etc/nginx/sites-enabled/status')
    plugin.set_default(:status_url, 'http://127.0.0.1:11311/status')
    plugin.set_default(:interval, 60)
  end

  def run_plugin
    File.exists? plugin.status_file
  end

  def collect
    status = Array.new
    lines = rest_get(plugin.status_url).split("\n")
    lines[2].scan(/\d+/).each_with_index do |value, index|
      status << { :service => plugin.service + " #{NGINX_STATUS_1[index]}", :metric => value.to_i, :as_diff => true }
    end
    # line[0]: Active connections: XXXX
    status << { :service => plugin.service + ' active', :metric => lines[0].split(':')[1].strip.to_i }
    # lines[3]: Reading: 0 Writing: 1 Waiting: 0
    lines[3].scan(/\d+/).each_with_index do |value, index|
      status << { :service => plugin.service + " #{NGINX_STATUS_2[index]}", :metric => value.to_i }
    end
    status
  end

end

