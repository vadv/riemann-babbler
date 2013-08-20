require 'yaml'
require 'logger'
require 'resolv'

require 'riemann/babbler/support/deep_merge'
require 'riemann/babbler'
require 'riemann/babbler/support/responder'

class Riemann::Babbler::Starter

  attr_reader :logger
  attr_reader :opts
  attr_reader :config

  def initialize(opts, configatron)
    @opts = opts
    @config = configatron
    Configatron.log.level = Logger::FATAL
    Gem::Deprecate.skip = true
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def start!
    merge_config
    set_logger_lvl
    load_plugins
    $riemann = get_riemann
    Riemann::Responder.new(@config.riemann.responder.port, logger).start
    start_plugins!
  end

  def merge_config
    config_file =  if File.exist?( opts[:config] )
      YAML.load_file( opts[:config] ).to_hash
    else
      logger.warn "Can't load config file #{opts[:config]}"
      Hash.new
    end
    config_default = YAML.load_file( File.expand_path('../../../../config.yml', __FILE__) )
    config_from_file = config_default.deep_merge( config_file )
    config.configure_from_hash config_from_file
  end

  def set_logger_lvl
    case config.logger.level
    when 'INFO'
      logger.level = Logger::INFO
    when 'WARN'
      logger.level = Logger::WARN
    when 'ERROR'
      logger.level = Logger::ERROR
    when 'FATAL'
      logger.level = Logger::FATAL
    when 'UNKNOWN'
      logger.level = Logger::UNKNOWN
    else
      logger.level = Logger::DEBUG
    end
  end

  def load_plugins
    plugins = Array.new
    default_plugins_dir = File.expand_path('../plugins/', __FILE__)
    Dir.glob( default_plugins_dir + '/*.rb') do |file|
      plugins <<  file
    end

    unless config.plugins.dirs.nil?
      config.plugins.dirs.each do |dir|
        next unless Dir.exist? dir
        Dir.glob( dir + '/*.rb') do |file|
          plugins << file
        end
      end
    end

    unless config.plugins.files.nil?
      config.plugins.files.each do |file|
        plugins << file
      end
    end
    plugins.each { |plugin| require plugin }
    load_gems_plugins
    load_parent
  end

  def load_gems_plugins
    plugins = Array.new
    begin
      Gem.source_index.each do |gem|
        plugin_name = gem[1].to_s.scan(/\s+name=(.+)\s+/)[0][0]
        plugins << plugin_name.gsub('-','/') if plugin_name.include? 'riemann-babbler-plugin-'
      end
    rescue
      logger.error "Can't find gems riemann-babbler-plugin-"
    end
    plugins.each { |plugin| require plugin }
  end

  def load_parent
    config.to_hash[:plugins].each do |plugin, plugin_opts|
      next if plugin_opts.nil?
      next unless plugin_opts.kind_of? Hash
      create_class(plugin.capitalize, plugin_opts[:parent].capitalize) if plugin_opts.has_key? :parent
    end
  end

  def create_class(new_class, parent_class)
    cmd = "class Riemann::Babbler::#{new_class} < Riemann::Babbler::#{parent_class}; end;"
    cmd += "Riemann::Babbler.registered_plugins << Riemann::Babbler::#{new_class}"
    eval(cmd)
  end

  def get_riemann
    begin
      riemann_ip =  Resolv.new.getaddress(config.riemann.host)
      riemann = Riemann::Client.new(
        :host => riemann_ip,
        :port => config.riemann.port
      )
      riemann = ( config.riemann.proto == 'tcp' ) ? riemann.tcp : riemann
      riemann.connect if config.test_connect_on_start
    rescue
      logger.fatal "Can't resolv or connect to riemann host: #{config.riemann.host}"
      sleep 5
      retry
    end
    riemann
  end

  def started_plugins
    registered_plugins = Riemann::Babbler.registered_plugins.dup
    run_only = Array.new
    config.plugins.to_hash.keys.each { |key| run_only << key.to_s }
    registered_plugins.delete_if {|plugin| ! run_only.include? plugin.to_s.split('::').last.downcase }
    registered_plugins
  end

  def start_plugins!
    plugin_threads = started_plugins.map do |plugin|
      Thread.new {
        logger.unknown "Start plugin #{plugin}"
        plugin.new( config, logger, $riemann ).run
      }
    end

    # plugin control
    Signal.trap 'TERM' do
      plugin_threads.each( &:kill )
    end

    plugin_threads.each( &:join )
  end

end
