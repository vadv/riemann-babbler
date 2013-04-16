#encoding: utf-8

module Riemann
  class Babbler

    def helper_error(msg = "Unknown helper error")
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
      Timeout::timeout(5) {
        Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
          err = stderr.gets(nil)
          out = stdout.gets(nil)
          [stdin, stdout, stderr].each{|stream| stream.send('close')}
          exit_status = wait_thread.value
        end
      }
      rescue => e
        helper_error "#{e.class} #{e}\n#{e.backtrace.join "\n"}"
      end
      if exit_status.to_i > 0
        err = err.chomp if err
        helper_error(err)
      elsif out
        return out.chomp
      else
        # статус 0, вывода stdout нет
        return ""
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
