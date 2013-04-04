### Установка
```
gem install riemann-babbler
````

### Использование
```
$ riemann-babbler --help
Riemann-babbler is plugin manager for riemann-tools.

Usage:
       riemann-babbler [options]
where [options] are:
  --config, -c <s>:   Config file (default: /etc/riemann-babbler/config.yml)
  --version, -v:   Print version and exit
  --help, -h:   Show this message
```

### Описание конфига
Bubbler имеет собственные конифиги, значения полученные через --config будут смерджены 
```yaml
riemann:
  host: riemann.host # хост riemann куда слать сообщения
  port: 5555 # порт
  tags: # таги которые будут сообшатся
    - prod
    - web
  suffix: ".testing" # окончание `hostname` в граффите как начало

plugins:
  dirs:
    - /etc/riemann/plugins # загружает все плагины из указаной дирректории
  files:
    - /var/lib/riemann-plugins/test.rb # подгружает плагин по указаному пути
```
##### Настройки конкретного плагина
```yaml
plugins:
  awesome_plugin:
  	service: some critical service # описание сервиса для поста на riemann
  	interval: 1 # как часто дергать плагин (в сек)
  	states:
  		warning: 80 # какой стейт давать плагину когда метрика перевалит за указанное значение
  		critical: 90 # соответственно стейт critical
  	some_parametr: "pgsql://username:password@database" # например необходимая настройка для плагина
```

### Написание собственного плагина
```ruby
class Riemann::Babbler::Awesomeplugins
  include Riemann::Babbler

  # быстрый доступ к конфигу
  def plugin
    options.plugins.awesome_plugin
  end

  # то что будет вызыватся таймером по указаному interval
  def tick
    status = {
      :service => plugin.service,
      :state => 'ok'
    }
    report status
  end

end
# обязательный вызов
Riemann::Babbler::Awesomeplugins.run
```
