class Riemann::Babbler::Dummy
  include Riemann::Babbler

  def plugin
    options.plugins.babbler
  end

  def tick
    status = {
      :service => plugin.service,
      :state => 'ok'
    }
    report status
  end

end

Riemann::Babbler::Dummy.run
