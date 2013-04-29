#encoding: utf-8

class Riemann::Babbler::La < Riemann::Babbler

  def collect
    { :service => plugin.service + ' la_1', :description => 'LA averaged over 1 minute', :metric => File.read('/proc/loadavg').split(/\s+/)[2].to_f }
  end

end
