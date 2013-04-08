class Riemann::Babbler::Disk < Riemann::Babbler

  require 'sys/filesystem'
  include Sys

  NOT_MONITORING_FS = [
    'sysfs',
    'nfs',
    'devpts',
    'squashfs',
    'proc',
    'devtmpfs'
  ]

  def plugin
    options.plugins.disk
  end

  def disk
    # собираем только необходимые для мониторинга маунт-поинты
    # точнее выбираем из mounts только те, у которых fstype не попадает
    # в NOT_MONITORING_FS
    monit_points = [] 
    File.read('/proc/mounts').split("\n").each do |line|
      mtab = line.split(/\s+/)
      monit_points << mtab[1] unless NOT_MONITORING_FS.include? mtab[2] 
    end
    disk = Hash.new
    monit_points.each do |point|
      point_stat = Filesystem.stat point
      human_point = point == "/" ? "/root" : point
      human_point.gsub!(/^\//, "")
      human_point.gsub!(/\//, "_")
      disk.merge!({human_point + " block" => 1 - point_stat.blocks_available.to_f/point_stat.blocks})
      disk.merge!({human_point + " inode" => 1 - point_stat.files_available.to_f/point_stat.files})
    end
    disk
  end

  def tick
    disk.each do |point, free|
      report({
        :service => plugin.service + " #{point}",
        :state => state(free),
        :metric => free
      })
    end
  end

end
