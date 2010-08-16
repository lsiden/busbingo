require 'logger'

module BusBingo

  def logger
    if (@_logger.nil?) then
      @_logger = Logger.new(STDERR)
      log_level = ENV['LOG_LEVEL'] || 'INFO'
      @_logger.level = eval("Logger::#{log_level}")
    end
    @_logger
  end
end
