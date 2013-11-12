require 'socket'

class Riemann::Babbler::Plugin::ResponderUdp < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:port, opts.riemann.responder_udp_port)
    plugin.set_default(:host, '127.0.0.1')
  end

  def process(data, src)
    begin
      report event_from_json(data)
      src.reply "sended\n"
    rescue
      log :error, "Failed to send message: #{data.inspect}"
      src.reply "failed to send: #{data.inspect}\n"
    end    
  end

  def run!
    log :unknown, "Start udp server at #{plugin.host}:#{plugin.port}"
    Socket.udp_server_loop(plugin.host, plugin.port) do |data, src|
      log :debug, "Recived data: #{data.inspect}, from client: #{src.inspect}"
      process(data, src) 
    end
  end

end
