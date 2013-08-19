require 'socket'
require 'json'

server = TCPServer.open(55755)

info = {
    :version => Riemann::Babbler::VERSION,
    :ruby => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}"
}

t = Thread.new {
  loop {
    client = server.accept
    client.puts info.to_json
    client.close
  }
}

t.join