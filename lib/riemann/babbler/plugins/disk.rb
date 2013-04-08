class Riemann::Babbler::Disk
  include Riemann::Babbler

  require 'sys/filesystem'
  include Sys

  NOT_MONITORING_FS = [
    'sysfs',
    'nfs',
    'devpts',
    'squashfs',
    'proc'
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
      disk.merge!({point + " storage" => (point_stat.blocks_free/point_stat.blocks_available)})
      disk.merge!({point + " inode" => (point_stat.files_free/point_stat.files_available)})
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

Riemann::Babbler::Disk.run
