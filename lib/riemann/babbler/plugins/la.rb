class Riemann::Babbler::La
  include Riemann::Babbler

  def plugin
    options.plugins.la
  end

  def la 
    File.read('/proc/loadavg').split(/\s+/)[2].to_f
  end

  def tick
    current_state = la
    status = {
      :service => plugin.service,
      :state => state(current_state),
      :metric => current_state
    }
    report status
  end

end

Riemann::Babbler::La.run
