[![Build Status](https://travis-ci.org/vadv/riemann-babbler.png)](https://travis-ci.org/vadv/riemann-babbler)

### Beware!
Currently I'm working on c-ext from zabbix. 
It's not all fully working :)
Use stable gem please!
```
gem "riemann-babbler", "~> 1.0.7.3"
```

### Install
```
gem install riemann-babbler
````

### Use
```
$ riemann-babbler --help
Riemann-babbler is plugin manager for riemann-tools.

Usage:
       riemann-babbler [options]
where [options] are:
  --config, -c:   Config file (default: /etc/riemann-babbler/config.yml)
  --version, -v:   Print version and exit
  --help, -h:   Show this message
```

### Config
Babbler load main config and merge custom plugins
```yaml
riemann:
  host: riemann.host 
  port: 5555 
  tags: 
    - prod
    - web
  suffix: ".testing"
  preffix: "prefix"

plugins:
  dirs:
    - /etc/riemann/plugins # load all rb files in dirs
  files:
    - /var/lib/riemann-plugins/test.rb # and custom load somefile
```
##### Config yml for custom plugin
```yaml
plugins:
  awesome_plugin:
  	service: some critical service
  	interval: 1 # (in sec)
  	states:
  		warning: 80
  		critical: 90
  	url: "http://127.0.0.1:11311/status"
```

### Custom Plugin
#### Example 1
```ruby
class Riemann::Babbler::Awesomeplugin < Riemann::Babbler

  def init
    plugin.set_default(:service, 'awesome plugin' )
    plugin.set_default(:interval, 1 )
    plugin.set_default(:url, 'http://127.0.0.1:11311/status')
  end

  def collect
    state = rest_get plugin.url == "OK" ? 'ok' : 'critical' # rest_get - helper
    {
      :service => plugin.service,
      :state => state
    }
  end
end
```
#### Example 2
```ruby
class Riemann::Babbler::Awesomeplugin < Riemann::Babbler

  def init
    plugin.set_default(:service, 'awesome plugin' )
    plugin.set_default(:interval, 1 )
    plugin.states.set_default(:warning, 5)
    plugin.states.set_default(:critical, 20)
    plugin.set_default(:cmd1, 'cat /file/status | grep somevalue')
    plugin.set_default(:cmd2, 'cat /file/status | grep somevalue2')
  end

  def run_plugin # run plugin if
    File.exists? '/file/status'
  end

  def collect # may return Array
    status = []
    status << {
        :service => plugin.service + " cmd1",
        :metric => shell plugin.cmd2 # shell - helper
        }
    status <<  {
        :service => plugin.service + " cmd2",
        :metric => shell plugin.cmd2, # shell - helper
        :as_diff => true # report as diffencial: current - last
      }
    status
  end
end
```
