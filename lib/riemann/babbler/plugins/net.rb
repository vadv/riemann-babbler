class Riemann::Babbler::Net
  include Riemann::Babbler

  def plugin
    options.plugins.net
  end

  def net
    f = File.read('/proc/net/dev')
    net = f.split("\n").inject({}) do |s, line|
      if line =~ /\s*(\w+?):\s*([\s\d]+)\s*/
        iface = $1

        ['rx bytes',
        'rx packets',
        'rx errs',
        'rx drop',
        'rx fifo',
        'rx frame',
        'rx compressed',
        'rx multicast',
        'tx bytes',
        'tx packets',
        'tx drops',
        'tx fifo',
        'tx colls',
        'tx carrier',
        'tx compressed'].map do |service|
          "#{iface} #{service}"
        end.zip(
          $2.split(/\s+/).map { |str| str.to_i }
        ).each do |service, value|
          s[service] = value
        end
      end
      
      puts s
    end
  end

  def tick
    status = {
      :service => plugin.service,
      :state => 'ok'
    }
    report status
  end

end

Riemann::Babbler::Net.run
