class Riemann::Babbler::Chkfile < Riemann::Babbler

  def init
    plugin.set_default(:service, 'check state file')
    plugin.states.set_default(:critical, 1)
    plugin.set_default(:file, '/var/tmp/error.txt')
    plugin.set_default(:interval, 60)
    plugin.set_default(:lines, 5)
  end

  def collect
    content = File.read(plugin.file).split("\n").delete_if {|x| x.strip.empty? }
    {
        :service => plugin.service + " file #{plugin.file}",
        :description => content.last(plugin.lines).join("\n"),
        :metric => content.count
    }
  end

end

