require 'socket'
require 'json'

class Riemann::Responder

  INFO = {
      :version => Riemann::Babbler::VERSION,
      :ruby => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}"
  }.freeze

  def initialize( port = 55755 )
    @port = port
  end

  def start
    @worker_thread = Thread.new {
      Socket.tcp_server_loop(@port) do |sock, _|
        begin
          sock.puts INFO.to_json
        ensure
          sock.close
        end
      end
    }
  end

  def stop
    if @worker_thread
      @worker_thread.kill
      @worker_thread = nil
    end
  end
end