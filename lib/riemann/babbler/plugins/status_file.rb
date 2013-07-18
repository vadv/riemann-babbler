class Riemann::Babbler::StatusFile < Riemann::Babbler

  def init
    plugin.set_default(:service, 'check state file')
    plugin.states.set_default(:critical, 1)
    plugin.set_default(:file, '/var/tmp/error.txt')
    plugin.set_default(:interval, 60)
    plugin.set_default(:max_lines, 100)
    plugin.set_default(:report_lines, 5)
  end

  def collect
    return [] unless File.exists? plugin.file
    content = File.read(plugin.file).split("\n").delete_if {|x| x.strip.empty? }
    {
        :service => plugin.service + " #{plugin.file}",
        :description => content.last(plugin.report_lines).join("\n"),
        :metric => content.count
    }
  end

end

