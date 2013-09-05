module Beefcake
  class Buffer
    
    def initialize(buf='')
      if buf.respond_to?(:force_encoding)
        self.buf = buf.force_encoding('BINARY')
      else
        self.buf = buf
      end
    end

    def append_string(s)
      append_uint64(s.length)
      if s.respond_to?(:force_encoding)
        self << s.force_encoding('BINARY')
      else
        self << s
      end
    end
    alias :append_bytes :append_string
    
  end
end

class File
  def tail(n)
    buffer = 1024
    idx = (size - buffer).abs
    chunks = []
    lines = 0
    begin
      seek(idx)
      chunk = read(buffer)
      lines += chunk.count("\n")
      chunks.unshift chunk
      idx -= buffer
    end while lines < ( n + 1 ) && pos != 0
    tail_of_file = chunks.join('')
    ary = tail_of_file.split(/\n/)
    lines_to_return = ary[ ary.size - n, ary.size - 1 ]
  end
end
