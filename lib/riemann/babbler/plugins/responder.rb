require 'net/http/server'
require 'json'

class Riemann::Babbler::Plugin::Responder < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:port, opts.riemann.responder_port)
    plugin.set_default(:started_at, Time.now.to_i)
  end

  def info
    {
        :version => Riemann::Babbler::VERSION,
        :ruby    => "#{RUBY_VERSION}-#{RUBY_PATCHLEVEL}",
        :uptime  => Time.now.to_i - plugin.started_at,
        :errors  => opts.errors.to_hash,
        :config  => opts.riemann.to_hash
    }
  end

  def run!
    log :unknown, "Start responder 0.0.0.0:#{plugin.port}"
    ::Net::HTTP::Server.run(:port => plugin.port) do |request, _|
      log :debug, "Responder request: #{request}"
      [200, { 'Content-Type' => 'application/json' }, [info.to_json]]
    end
  end

end