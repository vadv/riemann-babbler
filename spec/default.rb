#encoding: utf-8

$: << File.dirname(__FILE__) + '/../ext/sysinfo'
require 'riemann/babbler/plugin'
require 'start'
require 'configatron'

opts = Hash.new
opts[:config] = File.expand_path('../config.yml', __FILE__)

babbler = Riemann::Babbler::Starter.new(opts, configatron)

describe Riemann::Babbler do

  it 'Merge config' do
    babbler.merge_config
    configatron.riemann.host.should eq 'hostname_does_not_exists'
  end

  it 'Set logger lvl' do
    babbler.set_logger_lvl
    babbler.logger.level.should eq 4
  end

  it 'Load plugins' do
    babbler.load_plugins
    Riemann::Babbler.registered_plugins.should include( Riemann::Babbler::Dummy )
  end

  it 'Started plugins' do
    babbler.started_plugins.should include( Riemann::Babbler::Dummy )
  end

  it 'Parent plugins' do
    babbler.started_plugins.should include( Riemann::Babbler::Dummy2 )
  end

  it 'Custom parent plugin start' do
    dummyplugin = Riemann::Babbler::Dummy2.new(configatron, nil, nil)
    configatron.plugins.dummy2.to_hash.should include(:run => false)
    dummyplugin.plugin.run.should eq false
    dummyplugin.plugin.interval.should eq 2000 
    dummyplugin.run.should eq 0
  end

  it 'Shell helper' do
    dummyplugin = Riemann::Babbler::Dummy2.new(configatron, nil, nil)
    dummyplugin.shell("echo 'a' | wc -l").to_i.should eq 1
  end

  it 'RestGet helper' do
    dummyplugin = Riemann::Babbler::Dummy2.new(configatron, nil, nil)
    dummyplugin.rest_get('http://ya.ru').should include 'yandex.ru'
  end

  it 'TcpPortAviable helper' do
    dummyplugin = Riemann::Babbler::Dummy2.new(configatron, nil, nil)
    dummyplugin.tcp_port_aviable?('www.ya.ru', 80).should eq true
  end

end