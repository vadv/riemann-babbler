require 'net/http'
require 'csv'

class Riemann::Babbler::Haproxy < Riemann::Babbler
  
  def init
    plugin.set_default(:service, 'haproxy')
    plugin.set_default(:interval, 60)
    plugin.set_default(:url, 'http://user:password@localhost/stats;csv')
  end

  def collect
    status = Array.new
    content = rest_get(plugin.url)
    csv = CSV.parse(content.split("# ")[1], { :headers => true })
    csv.each do |row|
      row = row.to_hash
      ns  = "haproxy #{row['pxname']} #{row['svname']}"
      row.each do |property, metric|
        unless (property.nil? || property == 'pxname' || property == 'svname')
          status << {
            :service => "#{ns} #{property}",
            :metric  => metric.to_f,
            :state   =>  (['UP', 'OPEN'].include?(row['status']) ? 'ok' : 'critical')
          }
        end
      end
    end
    status
  end

end
