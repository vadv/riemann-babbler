#encoding: utf-8

class Riemann::Babbler::Memory < Riemann::Babbler

  def collect
    total = Memory.total
    free_bc = Memory.free + Memory.buffers + Memory.cached
    fraction = 1 - (free_bc.to_f / total)
    [
      { :service => plugin.service + ' % free', :description => 'Memory usage, %', :metric => fraction.round(2) * 100 },
      { :service => plugin.service + ' abs free', :description => "Memory free (Bytes)", :metric => Memory.free, :state => 'ok' },
      { :service => plugin.service + ' abs total', :description => "Memory total (Bytes)", :metric => total, :state => 'ok' },
      { :service => plugin.service + ' abs cached', :description => "Memory usage, cached (Bytes)",  :metric => Memory.cached, :state => 'ok' },
      { :service => plugin.service + ' abs buffers', :description => "Memory usage, buffers (Bytes)", :metric => Memory.buffers, :state => 'ok' },
      { :service => plugin.service + ' abs used', :description => "Memory usage, used (Bytes)", :metric => Memory.total - Memory.free , :state => 'ok' },
      { :service => plugin.service + ' abs free_bc', :description => "Memory usage with cache и buffers (Bytes)\n\n #{desc}", :metric => free_bc , :state => 'ok' }
    ]
  end

end
