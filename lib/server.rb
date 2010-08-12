# Copyright Westside Consulting LLC, Ann Arbor, MI, USA, 2010
  
require 'rubygems'
require 'sinatra'
require 'json'
require 'digest/sha1'
require 'rest_client'
require 'logger'
require 'pp'
require 'model'
require 'permutation'
#require 'fileutils'

class Sinatra::Application

  helpers do

    def set_long_expiration_header
      # set long expiration headers  
      one_year = 360 * 24 * 60 * 60 # a little less than a year for proxy's-sake
      time = Time.now + one_year
      time = time.to_time if time.respond_to?(:to_time)
      time = time.httpdate if time.respond_to?(:httpdate)

      response['Expires'] = time
      response['Cache-Control'] = "public, max-age=#{one_year}"
    end
  end

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
  # TODO - Replace this with '/card' or '/', id is in session
  get '/count-tiles' do
		BusBingo::TileTemplate.count.to_s
	end

  get '/mockup' do
    #FileUtils.pwd
    send_file('views/mock.html')
  end

  ###############
  # Games

  # Create a new card.
  post '/cards' do
		card = BusBingo::Card.new
		#tileTemplates = BusBingo::TileTemplate.all(:enabled => true) # does not work with SqlLite
		tileTemplates = BusBingo::TileTemplate.all
    while tileTemplates.length < 25 do
      tileTemplates << tileTemplates.clone
    end
    perm = Permutation.for(tileTemplates)
		perm.random.project
		card.tiles << tileTemplates[0, 24].map{|tt| BusBingo::Tile.new(:tile_template => tt)}
		card.player = BusBingo::Player.new # TODO - Player should be available from session
		card.save
		redirect "http://#{request.host}/cards/#{card.id}"
  end

  # Render page with card card.
  # TODO - Replace this with '/card' or '/', id is in session
  get '/cards/:id' do
    puts "id=#{params[:id]}"
    @card = BusBingo::Card.get(params[:id]) \
      or halt 404, 'Not Found'
    pp @card
    haml :card
  end

  # TODO - Requires admin session.
  # Render list of cards and their outcomes.
  get '/cards' do
    'Work in progress'
  end

  # For card :id, set <row, col> to state {0 = uncovered, anything else is covered}.
  # Returns header with x-busbingo-cardstate that matches /'[x ]{25}'(, winner)?/
  put 'card/:id/:row/:col/:state' do
    'Work in progress'
  end

  #################
  # Static Content

  get '/favicon.ico' do
    set_long_expiration_header
    send_file('views/images/favicon.ico');
  end

  get '/views/*' do
    # Get file path.  if refers to a directory, try index.html
    path = params[:splat].first.split('/')
    path = File.join('lib/views', *path)
    path = File.join(path, 'index.html') if File.directory?(path)
    #logger.debug(path)

    set_long_expiration_header

    # send actual file
    #Rack::Mime.mime_type('text/plain', nil); # throws exception ?
    send_file(path)
	end

  # Test that haml works
=begin
  get '/hello' do
    haml :hello
  end
=end
end
