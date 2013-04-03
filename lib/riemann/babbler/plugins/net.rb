class Riemann::Babbler::Net
  include Riemann::Babbler

  WORDS = ['rx bytes',
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
   'tx compressed']

  def plugin
    options.plugins.net
  end

  def net
    f = File.read('/proc/net/dev')
    status = Hash.new
    f.split("\n").inject({}) do |s, line|
      if line =~ /\s*(\w+?):\s*([\s\d]+)\s*/
        iface = $1
        WORDS.map do |service|
          "#{iface} #{service}"
        end.zip(
          $2.split(/\s+/).map { |str| str.to_i }
        ).each do |service, value|
          status.merge!({service => value})
        end
      end
    end
    return status
  end

  def tick
    net.each do |service, value|
    report({
      :service => service,
      :metric => value
    })
    end
  end

end

Riemann::Babbler::Net.run
