#encoding: utf-8

class Riemann::Babbler::Memory < Riemann::Babbler

  def collect
    total = SysInfo::Memory.total
    free_bc = SysInfo::Memory.free + SysInfo::Memory.buffers + SysInfo::Memory.cached
    fraction = 1 - (free_bc.to_f / total)
    [
      { :service => plugin.service + ' % free', :description => 'Memory usage, %', :metric => fraction.round(2) * 100 },
      { :service => plugin.service + ' abs free', :description => "Memory free (Bytes)", :metric => SysInfo::Memory.free, :state => 'ok' },
      { :service => plugin.service + ' abs total', :description => "Memory total (Bytes)", :metric => total, :state => 'ok' },
      { :service => plugin.service + ' abs cached', :description => "Memory usage, cached (Bytes)",  :metric => SysInfo::Memory.cached, :state => 'ok' },
      { :service => plugin.service + ' abs buffers', :description => "Memory usage, buffers (Bytes)", :metric => SysInfo::Memory.buffers, :state => 'ok' },
      { :service => plugin.service + ' abs used', :description => "Memory usage, used (Bytes)", :metric => SysInfo::Memory.total - SysInfo::Memory.free , :state => 'ok' },
      { :service => plugin.service + ' abs free_bc', :description => "Memory usage with cache и buffers (Bytes)\n\n #{desc}", :metric => free_bc , :state => 'ok' }
    ]
  end

end
