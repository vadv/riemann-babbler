class Riemann::Babbler::Dummy
  include Riemann::Babbler

  def collect
    {
      :state => 'ok'
    }
  end

end
