#encoding: utf-8

class Riemann::Babbler::Plugin::Disk < Riemann::Babbler::Plugin

  require 'sys/filesystem'
  include Sys

  NOT_MONITORING_FS = %w(sysfs nfs devpts squashfs proc devtmpfs)

  def init
    plugin.set_default(:service, 'disk')
    plugin.states.set_default(:warning, 70)
    plugin.states.set_default(:critical, 85)
  end

  def collect
    # собираем только необходимые для мониторинга маунт-поинты
    # точнее выбираем из mounts только те, у которых fstype не попадает
    # в NOT_MONITORING_FS
    monit_points = []
    File.open('/proc/mounts', 'r') do |file|
      while (line = file.gets)
        mtab = line.split(/\s+/)
        monit_points << mtab[1] unless NOT_MONITORING_FS.include? mtab[2]
      end
    end
    disk = Array.new
    monit_points.each do |point|
      point_stat  = Filesystem.stat point
      human_point = point == '/' ? '/root' : point
      human_point = human_point.gsub(/^\//, '').gsub(/\//, '_')
      disk << { :service => plugin.service + " #{human_point} % block", :description => "Disk usage #{point}, %", :metric => (1- point_stat.blocks_available.to_f/point_stat.blocks).round(2) * 100 } unless point_stat.blocks == 0
      disk << { :service => plugin.service + " #{human_point} % inode", :description => "Disk usage #{point}, inodes %", :metric => (1 - point_stat.files_available.to_f/point_stat.files).round(2) * 100 } unless point_stat.files == 0
      disk << { :service => plugin.service + " #{human_point} abs free", :description => "Disk free #{point}, B", :metric => point_stat.blocks_free * point_stat.block_size, :state => 'ok' }
      disk << { :service => plugin.service + " #{human_point} abs total", :description => "Disk space #{point}, B", :metric => point_stat.blocks * point_stat.block_size, :state => 'ok' }
    end
    disk
  end

end
