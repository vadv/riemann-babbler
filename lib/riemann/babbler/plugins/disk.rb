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

  def collect
    # собираем только необходимые для мониторинга маунт-поинты
    # точнее выбираем из mounts только те, у которых fstype не попадает
    # в NOT_MONITORING_FS
    monit_points = [] 
    File.read('/proc/mounts').split("\n").each do |line|
      mtab = line.split(/\s+/)
      monit_points << mtab[1] unless NOT_MONITORING_FS.include? mtab[2] 
    end
    disk = Array.new
    monit_points.each do |point|
      point_stat = Filesystem.stat point
      human_point = point == "/" ? "/root" : point
      human_point.gsub!(/^\//, "").gsub!(/\//, "_")
      disk << { :service => plugin.service + " #{human_point} % block", :metric => 1 - point_stat.blocks_available.to_f/point_stat.blocks }
      disk << { :service => plugin.service + " #{human_point} % inode", :metric => 1 - point_stat.files_available.to_f/point_stat.files }
      disk << { :service => plugin.service + " #{human_point} free", :metric =>  point_stat.blocks_free * point_stat.block_size, :state => 'ok'}
      disk << { :service => plugin.service + " #{human_point} total", :metric =>  point_stat.blocks * point_stat.block_size, :state => 'ok'}
    end
    disk
  end

end
