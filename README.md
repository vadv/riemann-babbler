[![Build Status](https://travis-ci.org/vadv/riemann-babbler.png)](https://travis-ci.org/vadv/riemann-babbler)

# Unsupported, use [kurchatov](https://github.com/vadv/kurchatov)

### Install
```
gem install riemann-babbler
````

### Use
```
$ riemann-babbler --help
Riemann-babbler is tool for monitoring with riemann.

Usage:
       riemann-babbler [options]
where [options] are:
                                       --config, -c <s>:   Config file (default: /etc/riemann-babbler/config.yml)
                                         --host, -h <s>:   Riemann server (default: 127.0.0.1)
                                         --port, -p <i>:   Riemann server default port (default: 5555)
                                      --backlog, -b <i>:   Riemann server backlog for events (default: 100)
                                      --timeout, -t <i>:   Riemann timeout (default: 5)
                                  --fqdn, --no-fqdn, -f:   Use fqdn for event hostname (default: true)
                                          --ttl, -l <i>:   TTL for events (default: 60)
                                     --interval, -i <i>:   Seconds between updates (default: 60)
                                    --log-level, -o <s>:   Level log (default: DEBUG)
                            --plugins-directory, -d <s>:   Directory for plugins (default: /usr/share/riemann-babbler/plugins)
                                        --tcp, --no-tcp:   Use TCP transport instead of UDP (improves reliability, slight overhead. (Default: true)
  --minimize-event-count, --no-minimize-event-count, -m:   Minimize count of sent messages (default: true)
                          --responder-bind-http, -r <s>:   Bind to http responder (default: 0.0.0.0:55755)
                           --responder-bind-udp, -e <s>:   Bind to udp responder (default: 0.0.0.0:55955)
                                          --version, -v:   Print version and exit
                                                 --help:   Show this message
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
class Riemann::Babbler::Plugin::AwesomePlugin < Riemann::Babbler::Plugin

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
class Riemann::Babbler::Plugin::AwesomePlugin < Riemann::Babbler::Plugin

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
        :as_diff => true # report as differential: current - last
      }
    status
  end
end
```
