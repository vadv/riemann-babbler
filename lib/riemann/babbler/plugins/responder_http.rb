require 'net/http/server'
require 'json'

class Riemann::Babbler::Plugin::ResponderHttp < Riemann::Babbler::Plugin

  def init
    host, port = opts.riemann.responder_bind_http.split(':')
    plugin.set_default(:port, port)
    plugin.set_default(:host, host)
    plugin.set_default(:started_at, Time.now.to_i)
  end

  def info
    {
        :version => Riemann::Babbler::VERSION,
        :ruby    => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}",
        :uptime  => Time.now.to_i - plugin.started_at,
        :errors  => opts.errors.to_hash,
        :config  => opts.riemann.to_hash
    }.to_json
  end

  def status_ok
    {:status => 'ok'}.to_json
  end

  def run!
    log :unknown, "Start responder #{plugin.host}:#{plugin.port}"
    ::Net::HTTP::Server.run(:port => plugin.port, :host => plugin.host) do |request, _|
      log :debug, "Responder request: #{request}"
      case
        when request[:uri][:path] == "/kill" #&& request[:method] == "POST"
          [200, { 'Content-Type' => 'application/json' }, [status_ok]]
          Process.kill('TERM', $$)
      else
        [200, { 'Content-Type' => 'application/json' }, [info]]
      end
    end
  end

end
