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
require 'haml'
#require 'fileutils'

class Sinatra::Application

  # some configuration
  enable :dump_errors, :logging
  disable :show_exceptions

  helpers do

    def set_long_expiration_header
      # set long expiration headers  
      one_year = 360 * 24 * 60 * 60 # a little less than a year for proxy's-sake
      time = Time.now + one_year
      time = time.to_time if time.respond_to?(:to_time)
      time = time.httpdate if time.respond_to?(:httpdate)
=begin
      headers 'Expires' => time, \
              'Cache-Control' => "public, max-age=#{one_year}"
=end
      response['Expires'] = time
      response['Cache-Control'] = "public, max-age=#{one_year}"
    end

    def login
      json = RestClient.post('https://rpxnow.com/api/v2/auth_info',
                             :token => params[:token],
                             :apiKey => '8aa5b41a23857ec2bfa56f4cb3d9aedf15ae0148',
                             :format => 'json', :extended => 'true')
      auth_response = JSON.parse(json)
      logger.debug "auth_response=#{auth_response.pretty_inspect}"

      if auth_response['stat'] == 'ok' then
        create_session_for(auth_response['profile']['identifier'])
      elsif err = auth_response['err'] then
        logger.info "Login failed; RPX auth_response #{err['code']}: #{err['msg']}"
      else
        logger.warn "Login failed; #{auth_response.pretty_inspect}"
      end
      redirect '/'
    end

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
    tileTemplates = []
    nTiles = BusBingo::Card::N_ROWS * BusBingo::Card::N_COLS
    while tileTemplates.length < nTiles do
      tileTemplates += BusBingo::TileTemplate.all
    end
    card.tiles = Permutation.for(tileTemplates).random!.project(tileTemplates)[0, nTiles] \
      .map {|tt| BusBingo::Tile.new(:tile_template => tt)}
    card.player = BusBingo::Player.new # TODO - Player should be available from session
    card.save
    redirect "http://#{request.host}:#{request.port}/cards/#{card.id}"
  end

  # Render page with card card.
  # TODO - Replace this with '/card' or '/', id is in session
  get '/cards/:id' do
    @card = BusBingo::Card.get(params[:id]) \
      or halt 404, 'Not Found'
    haml :card
  end

  # TODO - Requires admin session.
  # Render list of cards and their outcomes.
  get '/cards' do
    'Work in progress'
  end

  # For card :id, set <row, col> to state {0 = uncovered, anything else is covered}.
  # Returns header with x-busbingo-has-bingo that matches /'[x ]{nTiles}'(, winner)?/
  put '/cards/:id' do
    card = BusBingo::Card.get(params[:id]) \
      or halt 404, 'Not Found'
    #puts(params)
    row, col = params[:row].to_i, params[:col].to_i
    tile = card.tileAt(row, col)
    tile.covered = (params[:covered] === "true")
    tile.save
    headers 'x-busbingo-has-bingo' => card.has_bingo?(row, col) ? "true" : "false"
    status 200
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

    # send actual file
    #Rack::Mime.mime_type('text/plain', nil); # throws exception ?
    set_long_expiration_header
    send_file(path)
  end

  # Test that haml works
=begin
  get '/hello' do
    haml :hello
  end
=end
end
