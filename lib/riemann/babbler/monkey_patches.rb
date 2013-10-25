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

# https://raw.github.com/Offirmo/hash-deep-merge/master/lib/hash_deep_merge.rb
class Hash

  def deep_merge!(specialized_hash)
    internal_deep_merge!(self, specialized_hash)
  end


  def deep_merge(specialized_hash)
    internal_deep_merge!(Hash.new.replace(self), specialized_hash)
  end


  protected

  def internal_deep_merge!(source_hash, specialized_hash)
    specialized_hash.each_pair do |rkey, rval|
      if source_hash.has_key?(rkey) then
        if rval.is_a?(Hash) and source_hash[rkey].is_a?(Hash) then
          internal_deep_merge!(source_hash[rkey], rval)
        elsif rval == source_hash[rkey] then
        else
          source_hash[rkey] = rval
        end
      else
        source_hash[rkey] = rval
      end
    end

    source_hash
  end
end
