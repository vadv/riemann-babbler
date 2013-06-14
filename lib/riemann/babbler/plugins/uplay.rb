require 'json'
require 'socket'

class Riemann::Babbler::Uplay < Riemann::Babbler

  def myip
    ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
    myip = ip.ip_address if ip
    myip || '127.0.0.1'
  end

  def panel_id
    mac = File.read('/proc/sys/kernel/hostname').strip.downcase.split('-')[1]
    JSON.parse( rest_get(plugin.base_url + "/#{mac}.json") )['panel']['id']
  end

  def init
    plugin.set_default(:service, 'uplay')
    plugin.set_default(:file, '/var/run/status.json')
    plugin.set_default(:base_url, 'http://localhost/api/cubox/v1/panels' )
    plugin.statuses.set_default(:status_update_ts, 100)
    plugin.statuses.set_default(:application_uptime, 100)
    plugin.statuses.set_default(:video_unit_rate, 25)
    plugin.statuses.set_default(:player_state, 'Stream SPIF2')
    plugin.set_default(:interval, 60)
    @panel_id = panel_id
  end

  def run_plugin
    File.exists? plugin.file
  end


  def collect
    now = Time.now.to_i
    array = Array.new
    status = JSON.parse File.read(plugin.file)

    ip = myip
    info = ", ip: #{myip}, id: #{@panel_id}"

    # "status_update_ts" - время последнего обновления содержимого статусного файла в unix-timestamp
    if now - status['status_update_ts'] > plugin.statuses.status_update_ts
      array << { :service => plugin.service + ' status_update_ts', :description => 'update status very old' + info, :metric => now - status['status_update_ts'], :state => 'critical' }
    else
      array << { :service => plugin.service + ' status_update_ts', :description => 'update status time ok' + info, :metric => now - status['status_update_ts'], :state => 'ok' }
    end

    # "application_uptime" - время работы приложения, в секундах
    if now - status['application_uptime'] < plugin.statuses.application_uptime
      array << { :service => plugin.service + ' application_uptime', :description => "application uptime: (#{status['application_uptime']}) is very small" + info, :metric => now - status['application_uptime'], :state => 'critical' }
    else
      array << { :service => plugin.service + ' application_uptime', :description => 'application uptime ok' + info, :metric => now - status['application_uptime'], :state => 'ok' }
    end

    # "enough_decoded_frames" - достаточно ли фреймов успевает проходить через декодер (когда true, декодер не справляется), true/false
    unless status['enough_decoded_frames']
      array << { :service => plugin.service + ' enough_decoded_frames', :description => 'status enough_decoded_frames ok' + info, :metric => 0, :state => 'ok' }
    else
      array << { :service => plugin.service + ' enough_decoded_frames', :description => 'Uplay not cope with the load' + info, :metric => 1, :state => 'critical' }
    end

    # "enough_net_frames" - достаточно ли фреймов приходит по сети, true/false
    if status['enough_net_frames']
      array << { :service => plugin.service + ' enough_net_frames', :description => 'status enough_net_frames ok' + info, :metric => 0, :state => 'ok' }
    else
      array << { :service => plugin.service + ' enough_net_frames', :description => 'Not enough net frames to play' + info, :metric => 1, :state => 'critical' }
    end

    # "bytes_received" - общее количество принятых байтов от сервера, число, в байтах
    if status['bytes_received'] - @old_bytes_received > 0
      array << { :service => plugin.service + ' bytes_received', :description => 'status bytes_received ok' + info, :metric => status['bytes_received'], :state => 'ok' }
    else
      array << { :service => plugin.service + ' bytes_received', :description => "Uplay can't report about new bytes in bytes_received" + info, :metric => status['bytes_received'], :state => 'critical' }
    end if @old_bytes_received
    @old_bytes_received = status['bytes_received']

    # "bytes_sent" - общее количество отправленных байтов в управляющий канал, число, в байтах
    if status['bytes_sent'] - @old_bytes_sent > 0
      array << { :service => plugin.service + ' bytes_sent', :description => 'status bytes_sent ok' + info, :metric => status['bytes_sent'], :state => 'ok' }
    else
      array << { :service => plugin.service + ' bytes_sent', :description => "Uplay can't report about new bytes in bytes_sent" + info, :metric => status['bytes_sent'], :state => 'critical' }
    end if @old_bytes_sent
    @old_bytes_sent = status['bytes_sent']

    # "have_audio" - заявлено ли аудио в этом потоке
    if status['have_audio']
      array << { :service => plugin.service + ' have_audio', :description => 'status have_audio ok' + info, :metric => 0, :state => 'ok' }
    else
      array << { :service => plugin.service + ' have_audio', :description => 'Video dont have aduio' + info, :metric => 1, :state => 'critical' }
    end

    # "stream_bit_rate" - общий битрейт потока за последнюю секунду, кбит/сек.
    array << { :service => plugin.service + ' stream_bit_rate', :description => 'stream bitrate' + info, :metric => status['stream_bit_rate'], :state => 'ok' }

    # "have_audio" - заявлено ли аудио в этом потоке
    if status['have_audio']
      array << { :service => plugin.service + ' have_audio', :description => 'status have_audio ok' + info, :metric => 0, :state => 'ok' }
    else
      array << { :service => plugin.service + ' have_audio', :description => 'Video dont have audio' + info, :metric => 1, :state => 'critical' }
    end

    # "video_unit_rate" - количество выведенных (показанных) видеофреймов за последнюю секунду
    if status['video_unit_rate'] - plugin.statuses.video_unit_rate >= 0
      array << { :service => plugin.service + ' video_unit_rate', :description => 'status video_unit_rate ok' + info, :metric => status['video_unit_rate'], :state => 'ok' }
    else
      array << { :service => plugin.service + ' video_unit_rate', :description => "Video rate is low (<#{plugin.statuses.video_unit_rate})" + info, :metric => status['video_unit_rate'], :state => 'critical' }
    end

    # "player_state" - состояние проигрывания ("Stream SPIF2" - играет поток SPIF2, 
    # "Dummy" - играет заставка, "Dummy (no video)" 
    # - должна играть заставка, но файл не обнаружен или не указан)
    if status['player_state'].to_s.include? plugin.statuses.player_state
      array << { :service => plugin.service + ' player_state', :description => "current player state: #{status['player_state']}" + info, :metric => 0, :state => 'ok' }
    else
      array << { :service => plugin.service + ' player_state', :description => "current player state: #{status['player_state']}" + info, :metric => 1, :state => 'critical' }
    end

    array
  end

end
