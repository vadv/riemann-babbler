#encoding: utf-8

class Riemann::Babbler::Plugin::Disk < Riemann::Babbler::Plugin

  require 'sys/filesystem'
  include Sys

  # check size:
  NOT_MONITORING_FS_FOR_SIZE = %w(sysfs nfs devpts squashfs proc devtmpfs)
  # fstab:
  MONITORING_FS_FOR_FSTAB = %w(ext2 ext3 ext4 xfs tmpfs)
  NOT_MONIT_DEVICE_FOR_FSTAB = %w(none)
  NOT_MONITORING_POINT_FOR_FSTAB = %w(/lib/init/rw /dev/shm /dev)

  def init
    plugin.set_default(:service, 'disk')
    plugin.states.set_default(:warning, 70)
    plugin.states.set_default(:critical, 85)
  end

  def get_fstab
    fstab = File.read('/etc/fstab').split("\n").delete_if { |x| x.strip.match(/^#/) }
    fstab.join("\n")
  end

  def get_monit_points_for_size
    # собираем только необходимые для мониторинга маунт-поинты
    # точнее выбираем из mounts только те, у которых fstype не попадает
    # в NOT_MONITORING_SIZE_FOR_FS
    monit_points = []
    File.open('/proc/mounts', 'r') do |file|
      while (line = file.gets)
        mtab = line.split(/\s+/)
        monit_points << mtab[1] unless NOT_MONITORING_FS_FOR_SIZE.include? mtab[2]
      end
    end
    monit_points
  end

  def get_monit_points_for_fstab
    # выбираем из mounts только те, у которых fstype попадает
    # в MONITORING_SIZE_FOR_FS
    monit_points = []
    File.open('/proc/mounts', 'r') do |file|
      while (line = file.gets)
        mtab = line.split(/\s+/)
        if MONITORING_FS_FOR_FSTAB.include?(mtab[2]) && 
            !NOT_MONITORING_POINT_FOR_FSTAB.include?(mtab[1]) && 
            !NOT_MONIT_DEVICE_FOR_FSTAB.include?(mtab[0])
          monit_points << mtab[1] 
        end
      end
    end
    monit_points
  end

  def collect
    fstab = get_fstab
    disk = Array.new
    get_monit_points_for_size.each do |point|
      point_stat  = Filesystem.stat point
      human_point = point == '/' ? '/root' : point
      human_point = human_point.gsub(/^\//, '').gsub(/\//, '_')
      disk << { :service => plugin.service + " #{human_point} % block", :description => "Disk usage #{point}, %", :metric => (1- point_stat.blocks_available.to_f/point_stat.blocks).round(2) * 100 } unless point_stat.blocks == 0
      disk << { :service => plugin.service + " #{human_point} % inode", :description => "Disk usage #{point}, inodes %", :metric => (1 - point_stat.files_available.to_f/point_stat.files).round(2) * 100 } unless point_stat.files == 0
      disk << { :service => plugin.service + " #{human_point} abs free", :description => "Disk free #{point}, B", :metric => point_stat.blocks_free * point_stat.block_size, :state => 'ok' }
      disk << { :service => plugin.service + " #{human_point} abs total", :description => "Disk space #{point}, B", :metric => point_stat.blocks * point_stat.block_size, :state => 'ok' }
    end
    get_monit_points_for_fstab.each do |point|
      disk << { :service => plugin.service + " #{point} fstab entry", :description => "Mount point #{point} not matched in /etc/fstab", :state => 'critical' } unless fstab.match("#{point} ")
    end
    disk
  end

end
