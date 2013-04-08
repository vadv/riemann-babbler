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
Bubbler load main config and merge custom plugins
```yaml
riemann:
  host: riemann.host 
  port: 5555 
  tags: 
    - prod
    - web
  suffix: ".testing"
  preffix: "previx"

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
```ruby
class Riemann::Babbler::Awesomeplugin < Riemann::Babbler

  def init
    plugin.set_default(:service, 'awesome plugin' )
    plugin.set_default(:interval, 1 )
    plugin.set_default(:url, 'http://127.0.0.1:11311/status')
  end
  def collect
    {
      :service => plugin.service,
      :metric => rest_get url # rest_get - helper
    }
  end

end
```
