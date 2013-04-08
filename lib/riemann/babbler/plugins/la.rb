class Riemann::Babbler::La < Riemann::Babbler

  def collect
  { 
    "la_1" => File.read('/proc/loadavg').split(/\s+/)[2].to_f
  }
  end

end
