# Copyright Westside Consulting LLC, Ann Arbor, MI, USA, 2010
  
require 'rubygems'
require 'sinatra'
require 'json'
require 'digest/sha1'
require 'rest_client'
require 'logger'
require 'pp'
require 'model'
#require 'fileutils'

class Sinatra::Application

  # some configuration
  enable :dump_errors, :logging

  helpers do
    def logger
      if (@_logger.nil?) then
        @_logger = Logger.new(STDERR)
        log_level = ENV['LOG_LEVEL'] || 'INFO'
        @_logger.level = eval("Logger::#{log_level}")
      end
      @_logger
    end

    def halt_with_message(code, msg)
      logger.warn msg
      headers 'Warning' => msg
      halt code, msg
    end

    def halt_on_exception(e)
      msg = "#{e.class.to_s}, #{e.message}"
      code = case e.class
             when JSON::ParserError then
               403
             else
               500
             end
      halt_with_message(code, msg)
    end
  end

  # Over-ride obnoxious "Sinatra doesn't know this ditty..." page.
  not_found do
    halt_with_message 404, "Path not found: #{request.path}"
  end

  error do
    halt_on_exception env['sinatra.error']
  end

  ###############
  # Tiles

  # Render edit form
  get '/tiles/new' do
    'Work in progress'
  end

  # Post tile edit form
  post '/tiles' do
    'Work in progress' # redirect to /tiles/:id
  end

  # Render page with all tiles
  get '/tiles' do
    'Work in progress'
  end

  # Render page with one tile
  get '/tiles/:id' do
    'Work in progress'
  end

  ###############
  # Mock page

  # Render page with game card.
  # TODO - Replace this with '/game' or '/', id is in session
  get '/mockup' do
    #FileUtils.pwd
    send_file('views/mock.html')
  end

  ###############
  # Games

  # Create a new game.
  post '/games' do
    'Work in progress'
  end

  # Render page with game card.
  # TODO - Replace this with '/game' or '/', id is in session
  get '/games/:id' do
    'Work in progress'
  end

  # TODO - Requires admin session.
  # Render list of games and their outcomes.
  get '/games' do
    'Work in progress'
  end

  # For game :id, set <row, col> to state {0 = uncovered, anything else is covered}.
  # Returns header with x-busbingo-gamestate that matches /'[x ]{25}'(, winner)?/
  put 'game/:id/:row/:col/:state' do
    'Work in progress'
  end

  #################
  # Static Content

  get '/views/*' do
    # Get file path.  if refers to a directory, try index.html
    path = params[:splat].first.split('/')
    path = File.join('views', *path)
    path = File.join(path, 'index.html') if File.directory?(path)
    #logger.debug(path)

    # set long expiration headers  
    one_year = 360 * 24 * 60 * 60 # a little less than a year for proxy's-sake
    time = Time.now + one_year
    time = time.to_time if time.respond_to?(:to_time)
    time = time.httpdate if time.respond_to?(:httpdate)

    response['Expires'] = time
    response['Cache-Control'] = "public, max-age=#{one_year}"

    # send actual file
    #Rack::Mime.mime_type('text/plain', nil); # throws exception ?
    send_file(path)
  end

end
