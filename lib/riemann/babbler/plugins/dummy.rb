class Riemann::Babbler::Dummy
  include Riemann::Babbler

  def plugin
    options.plugins.dummy
  end

  def status
    Random.rand(100)
  end

  def tick
    current_status = status
    status = {
      :service => plugin.service,
      :metric => current_status,
      :state => state(current_status)
    }
    log.debug "Report status: #{status.inspect}"
    report status
  end

end

Riemann::Babbler::Dummy.run
