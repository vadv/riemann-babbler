#encoding: utf-8

class Riemann::Babbler::Disk < Riemann::Babbler

  NOT_MONITORING_FS = %w(sysfs nfs devpts squashfs proc devtmpfs)

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
      human_point = point == '/' ? '/root' : point
      human_point = human_point.gsub(/^\//, '').gsub(/\//, '_')
      disk << { :service => plugin.service + " #{human_point} % block", :description => "Disk usage #{point}, %", :metric => FS::Block.pfree(point) }
      disk << { :service => plugin.service + " #{human_point} % inode", :description => "Disk usage #{point}, inodes %", :metric => FS::Inode.pfree(point)}
      disk << { :service => plugin.service + " #{human_point} abs free", :description => "Disk free #{point}, B", :metric =>  FS::Block.total(point), :state => 'ok'}
      disk << { :service => plugin.service + " #{human_point} abs total", :description => "Disk space #{point}, B",  :metric =>  FS::Inode.total(point), :state => 'ok'}
    end
    disk
  end

end
