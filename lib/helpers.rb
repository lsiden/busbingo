require 'logger'
require 'socket'
require 'set'
require 'uri'

module BusBingo
  module Helpers

    def logger
      if (@_logger.nil?) then
        @_logger = Logger.new(STDERR)
        log_level = ENV['LOG_LEVEL'] || 'INFO'
        @_logger.level = eval("Logger::#{log_level}")
      end
      @_logger
    end

    # Returns true iff app is running on a know local host.
    def localhost?
      %w(morpheus lsiden-laptop).to_set.include?(Socket.gethostname)
    end

    def uri_encode(s)
      # Got this snippet from http://snippets.dzone.com/posts/show/1260
      URI.escape(s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end
  end
end
