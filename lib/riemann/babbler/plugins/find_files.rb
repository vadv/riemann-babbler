require 'find'

class Riemann::Babbler::Plugin::FindFiles < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'find files')
    plugin.set_default(:interval, 60)
    plugin.set_default(:file_mask, '.*')       # file search mask
    plugin.set_default(:dir, '/tmp/directory') # search in dir
    plugin.set_default(:age, 1440)             # in minute
    plugin.states.set_default(:warning, 5)
  end

  def collect
    return [] unless File.directory?(plugin.dir)
    count_files = 0
    file_mask   = Regexp.new(plugin.file_mask)
    Find.find(plugin.dir).each do |file|
      next unless File.file? file
      next unless file_mask.match file
      next unless Time.now.to_i - (plugin.age * 60) > File.new(file).mtime.to_i
      count_files += 1
    end
    { :service => plugin.service, :metric => count_files, :description => "Count files in #{plugin.dir}" }
  end

end
