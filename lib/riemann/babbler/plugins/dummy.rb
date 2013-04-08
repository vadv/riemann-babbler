class Riemann::Babbler::Dummy < Riemann::Babbler

  def collect
    { :service => plugin.service , :state => 'ok'  }
  end

end
