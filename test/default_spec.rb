require_relative '../lib/riemann/babbler'

include Riemann::Babbler::Options

describe 'Riemann Babbler Loader' do

  before(:each) do
    merge_config(File.expand_path('../my_config.yml', __FILE__))
    @plugins = Riemann::Babbler::PluginLoader.new.plugin_to_start
    @plugins = @plugins.map {|plugin| plugin.to_s}
  end

  it "load from file" do
    opts.riemann.host.should == 'host_from_yaml'
  end

  it "load parent plugins" do
    @plugins.should include('Riemann::Babbler::Plugin::Disk_1')
  end

  it "load parent from array" do
    @plugins.should include('Riemann::Babbler::Plugin::Cpu_1')
  end
  
end