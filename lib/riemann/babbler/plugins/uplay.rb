# играет заставку или нормальное видео
# давно ли играет видео
# аптайм приложение

# "player_state":"Dummy", но при этом с rendg  есть соединение
# "player_state":"Stream SPIF2"  -

 
require 'json'

class Riemann::Babbler::Uplay < Riemann::Babbler

  def init
    plugin.set_default(:service, 'uplay')
    plugin.set_default(:file, '/var/run/status.json')
    plugin.statuses.set_default(:status_update_ts, 100)
    plugin.statuses.set_default(:application_uptime, 100)
    plugin.set_default(:interval, 60)
  end

  def run_plugin
    File.exists? plugin.file
  end


  def collect
    now = Time.now.to_i
    array = Array.new
    status = JSON.parse File.read(plugin.file)

    # "status_update_ts" - время последнего обновления содержимого статусного файла в unix-timestamp
    if now - status['status_update_ts'] > plugin.statuses.status_update_ts
      array << { :service => plugin.service + ' status_update_ts', :description => 'update status very old', :metric => now - status['status_update_ts'], :state => 'critical' }
    else
      array << { :service => plugin.service + ' status_update_ts', :description => 'update status time ok', :metric => now - status['status_update_ts'], :state => 'ok' }
    end

    # "application_uptime" - время работы приложения, в секундах
    if now - status['application_uptime'] < plugin.statuses.application_uptime
      array << { :service => plugin.service + ' application_uptime', :description => "application uptime: (#{status['application_uptime']}) is very small", :metric => now - status['application_uptime'], :state => 'critical' }
    else
      array << { :service => plugin.service + ' application_uptime', :description => 'application uptime ok', :metric => now - status['application_uptime'], :state => 'ok' }
    end

    # "enough_decoded_frames" - достаточно ли фреймов успевает проходить через декодер (когда true, декодер не справляется), true/false
    unless status['enough_decoded_frames']
      array << { :service => plugin.service + ' enough_decoded_frames', :description => 'status enough_decoded_frames ok', :metric => 0, :state => 'ok' }
    else
      array << { :service => plugin.service + ' enough_decoded_frames', :description => 'Uplay not cope with the load', :metric => 1, :state => 'critical' }
    end

    # "enough_net_frames" - достаточно ли фреймов приходит по сети, true/false
    if status['enough_net_frames']
      array << { :service => plugin.service + ' enough_net_frames', :description => 'status enough_net_frames ok', :metric => 0, :state => 'ok' }
    else
      array << { :service => plugin.service + ' enough_net_frames', :description => 'Not enough net frames to play', :metric => 1, :state => 'critical' }
    end

    array << { :service => plugin.service + ' player_state', :description => "current player state: #{status['player_state']}", :metric => 0, :state => 'ok' }

    array
  end

end