require "cgi"

class ToQuery
  attr_reader :hash

  def self.call(hash)
    new.call(hash)
  end

  def call(hash)
    @hash = hash
    to_query(hash)
  end

  private

  def to_query(hash)
    hash.collect do |key, value|
      if value.is_a?(Hash)
        to_query(value)
      else
        to_param(key, value)
      end
    end.compact.sort! * "&"
  end

  def to_param(key, value)
    "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
  end
end
