#encoding: utf-8

module Riemann
  class Babbler

    def helper_error(msg = 'Unknown helper error')
      report({
        :service => plugin.service,
        :state => 'critical',
        :description => msg
      })
      raise Riemann::Babbler::PluginHelperError
    end

    def plugin_timeout
      ( plugin.interval * 2 ).to_f/3
    end

    # хэлпер для парса stdout+stderr и exit status
    def shell(*cmd)
      exit_status=nil
      err=nil
      out=nil
      begin
        Timeout::timeout(plugin_timeout) {
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
        helper_error("Error while running shell: " + err.to_s)
      elsif out
        return out.strip
      else
        # статус 0, вывода stdout нет
        ''
      end
    end

    def file_grep(filename, regexp, max_lines=100)
      readed_lines = 0
      lines = Array.new
      begin
        Timeout::timeout(plugin_timeout) do
          File::Tail::Logfile.open(file, :backward => 0) do |log|
            log.tail do |line|
              readed_lines += 1
              lines << line if line.match?(regexp)
              return lines if readed_lines >= max_lines
            end
          end
        end
      rescue => e
        helper_error("#{e.class} #{e}\n#{e.backtrace.join "\n"}")
      end
      return lines
    end

    def tcp_port_aviable?(ip, port)
      begin
        Timeout::timeout(plugin_timeout) do
          begin
            s = TCPSocket.new(ip, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
        return false
      end
      false
    end

    # http rest
    def rest_get(url)
      begin
        Timeout::timeout(plugin_timeout) do
          begin
            RestClient.get url
          rescue
            helper_error("Get from url: #{url} failed")
          end
        end
      rescue Timeout::Error
        helper_error("Get from url: #{url}, timeout error")
      end
    end

    # unix timestamp
    def unixnow
      Time.now.to_i
    end

  end
end
