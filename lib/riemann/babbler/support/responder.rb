require 'socket'
require 'json'

class Riemann::Responder

  def info
    {
      :version => Riemann::Babbler::VERSION,
      :ruby => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}",
      :uptime => (Time.now.to_i - @started_at)
    }.to_json
  end

  def initialize( port = 55755 )
    @port = port
    @started_at = Time.now.to_i
  end

  def start
    @worker_thread = Thread.new {
      Socket.tcp_server_loop(@port) do |sock, _|
        begin
          sock.puts info
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