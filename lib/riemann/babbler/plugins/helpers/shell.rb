#encoding: utf-8

require 'open3'

module Riemann
  module Babbler
    module Plugins
      module Helpers

        # helper: stdout+stderr и exit status
        def shell(*cmd)
          exit_status=nil
          err        =nil
          out        =nil
          Timeout::timeout(plugin.timeout) {
            Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
              err = stderr.gets(nil)
              out = stdout.gets(nil)
              [stdin, stdout, stderr].each { |stream| stream.send('close') }
              exit_status = wait_thread.value
            end
          }
          if exit_status.to_i > 0
            err = err.chomp if err
            raise 'Error while running shell: ' + err.to_s
          elsif out
            return out.strip
          else
            # exit status 0, no stdout
            ''
          end
        end

      end
    end
  end
end
