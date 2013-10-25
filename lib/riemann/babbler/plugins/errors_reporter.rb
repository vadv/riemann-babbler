class Riemann::Babbler::Plugin::ErrorsReporter < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'riemann client')
    @report_ok = false
  end

  def collect
    status = Array.new
    messages = Array.new

    opts.errors.to_hash.each do |plugin_name, plugin_status|
      next if plugin_status[:reported]
      messages << "#{plugin_name} count_errors: #{plugin_status[:count]}, \
        last: #{plugin_status[:last_error_at]}"
      opts.errors.send(plugin_name).reported = true
    end

    if messages.empty?
      status << { :service => plugin.service, :state => 'ok', :description => "All plugins ok" } unless @report_ok
      @report_ok = true
    else
      @report_ok = false
      status << {
          :service => plugin.service,
          :state => 'critical',
          :metric => messages.count,
          :description => "Problem with plugins:\n #{messages.join("\n")}"
      }
    end
    status
  end

end
