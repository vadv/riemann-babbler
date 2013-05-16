class Riemann::Babbler::Dummy < Riemann::Babbler

  def collect
    if tcp_port_aviable?(riemann.host, riemann.port)
      logger.unknown "Riemann state 'ok' host: #{configatron.riemann.host}, port #{configatron.riemann.port}, proto tcp"
    else
      logger.fatal "Can't access to riemann host: #{configatron.riemann.host}, port #{configatron.riemann.port}, proto tcp" 
    end
    disk << { :service => plugin.service, :state => 'ok' }
  end

end
