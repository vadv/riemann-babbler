#encoding: utf-8

module Riemann
  class Babbler

    def helper_error(msg = 'Unknown helper error')
      report({
        :service => plugin.service,
        :state => 'critical',
        :description => msg
      })      
    end

    # хэлпер для парса stdout+stderr и exit status
    def shell(*cmd)
      exit_status=nil
      err=nil
      out=nil
      begin
      timeout_shell = ( plugin.interval * 2 ).to_f/3
      Timeout::timeout(timeout_shell) {
        Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
          [stdin, stdout, stderr].each{|stream| stream.send('close')}
        end
      }
      rescue => e
        helper_error "#{e.class} #{e}\n#{e.backtrace.join "\n"}"
      end
      if exit_status.to_i > 0
        err = err.chomp if err
        helper_error(err)
      elsif out
        return out.strip
      else
        # статус 0, вывода stdout нет
        ''
      end
    end

    # http rest 
    def rest_get(url)
      begin
        RestClient.get url
      rescue
        helper_error("Get from url: #{url}")
      end
    end

  end
end
