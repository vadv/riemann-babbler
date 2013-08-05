require 'find'

class Riemann::Babbler::FindOldFiles < Riemann::Babbler

  def init
    plugin.set_default(:service, 'find old files')
    plugin.set_default(:interval, 60)
    plugin.set_default(:file_mask, '.*') # file search mask
    plugin.set_default(:dir, '/tmp/directory') # search in dir
    plugin.set_default(:age, 1440) # in minute
    plugin.states.set_default(:warning, 5)
    plugin.states.set_default(:critical, 20)
  end

  def collect
    files = 0
    file_mask = Regexp.new(plugin.file_mask)
    puts "File: #{plugin.dir}"
    Find.find(plugin.dir).each do |file|
      next unless File.file? file
      next unless file_mask.match file
      next unless Time.now.to_i - (plugin.age * 60) > File.new(f).mtime.to_i
      files += 1
    end
    { :service => plugin.service, :metric => files, :description => "Count old files in #{plugin.dir}"}
  end

end
