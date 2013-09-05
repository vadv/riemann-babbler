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

class IO
  TAIL_BUF_LENGTH = 1 << 16

  def tail(n)
    return [] if n < 1

    seek -TAIL_BUF_LENGTH, SEEK_END

    buf = ""
    while buf.count("\n") <= n
      buf = read(TAIL_BUF_LENGTH) + buf
      seek 2 * -TAIL_BUF_LENGTH, SEEK_CUR
    end

    buf.split("\n")[-n..-1]
  end
end
