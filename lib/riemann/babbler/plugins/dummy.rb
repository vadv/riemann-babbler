class Riemann::Babbler::Dummy < Riemann::Babbler

  def collect
    if tcp_port_aviable?(configatron.riemann.host, configatron.riemann.port)
      logger.error "Riemann state 'ok' host: #{configatron.riemann.host}, port #{configatron.riemann.port}"
      []
    else
      logger.error "Can't access to riemann host: #{configatron.riemann.host}, port #{configatron.riemann.port}" 
    end
    Array.new
  end

end
