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
