require 'socket'
require 'json'

class Riemann::Babbler::Plugin::ResponderUdp < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:port, opts.riemann.responder_udp_port)
  end

  def process(data, src)
    begin
      msg = JSON.parse(data)
      msg.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      report(msg)
      src.reply "sended\n"
    rescue
      log :error, "Failed to send message: #{data.inspect}"
      src.reply "failed to send: #{data.inspect}\n"
    end    
  end

  def run!
    log :unknown, "Start udp server at #{plugin.port}"
    Socket.udp_server_loop(plugin.port) do |data, src|
      log :debug, "recived data: #{data.inspect}, from client: #{src.inspect}"
      process(data, src) 
    end
  end

end
