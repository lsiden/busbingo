# Copyright Westside Consulting LLC, Ann Arbor, MI, USA, 2010
  
require 'rubygems'
require 'sinatra'
require 'json'
require 'digest/sha1'
require 'rest_client'
require 'bb_logger'
require 'pp'
require 'model'
require 'permutation'
require 'haml'
require 'rest_client'
require 'digest/sha1'
#require 'fileutils'

class Sinatra::Application

  # some configuration
  #enable :dump_errors, :logging
  #enable :dump_errors
  #disable :show_exceptions

  helpers do
    include BusBingo

    SESSION_COOKIE_NAME = 'x-busbingo-session-id'

    # This session is different from env[rack.session].
    # It's maintained in the model.
    def get_session!
      # Insure that caller has a session.
      session_id = request.cookies[SESSION_COOKIE_NAME]
      logger.debug "#{path}: session_id=#{session_id}"
      return nil unless session_id

      session = BusBingo::Session.get(session_id)
      logger.debug "#{path}: session=#{session.pretty_inspect}"
      session.save # reset :updated_at on session
      return session
    end

    def set_long_expiration_header
      # set long expiration headers  
      one_year = 360 * 24 * 60 * 60 # a little less than a year for proxy's-sake
      time = Time.now + one_year
      time = time.to_time if time.respond_to?(:to_time)
      time = time.httpdate if time.respond_to?(:httpdate)
      response['Expires'] = time
      response['Cache-Control'] = "public, max-age=#{one_year}"
    end

    def create_session_for(player_id, email)
      digest_id = Digest::SHA1.hexdigest(player_id) 
      player = BusBingo::Player.get(digest_id)
      player ||= BusBingo::Player.create(:id => digest_id, :email => email)
      player.session = BusBingo::Session.new(:ip => request.ip)
      player.save
      return player.session
    end
    
  end

  # Over-ride obnoxious "Sinatra doesn't know this ditty..." page.
  not_found do
    throw :halt, [404, "Path not found: #{request.path}"]
  end

  ###############
  # Index page and login
  get '/' do
    session = get_session or redirect '/login'
    redirect "/cards/#{session.player.card.id}"
  end

  get '/login' do
    send_file('lib/views/login.html')
  end

  # Create new session for authenticated player.
  post '/sessions' do
    logger.debug "token=#{params[:token]}"
    json = RestClient.post('https://rpxnow.com/api/v2/auth_info',
                           :token => params[:token],
                           :apiKey => 'a684c5b0305f61508c906b4ca8da609a8ba3c257',
                           :format => 'json', :extended => 'true')
    auth_response = JSON.parse(json)
    logger.debug "auth_response=#{auth_response.pretty_inspect}"

    if auth_response['stat'] == 'ok' then
      profile = auth_response['profile']
      player_id = profile['identifier']
      email = profile['email']
      session = create_session_for(player_id, email)
      logger.info "Login successful - Created session for player=#{player_id}, ip=#{request.ip}"
      response.set_cookie(SESSION_COOKIE_NAME, {:value => session.id, :path => '/'})
      #logger.debug "HTTP response=#{self.response.pretty_inspect}"
      session.player.card = BusBingo::Card.new
      session.player.save
      redirect "/cards/#{session.player.card.id}"
    elsif err = auth_response['err'] then
      throw :halt, [403, "Login failed; RPX auth_response #{err['code']}: #{err['msg']}"]
    else
      throw :halt, [500, "Login failed; #{auth_response.pretty_inspect}"]
    end
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
    send_file('lib/views/mock.html')
  end

  ###############
  # Games

  # Create a new card.
  post '/cards' do
    session = get_session or redirect "/"
    card = session.player.new_card
    redirect "http://#{request.host}:#{request.port}/cards/#{card.id}"
  end

  # Render page with card card.
  # TODO - Replace this with '/card' or '/', id is in session
  get '/cards/:id' do
    session = get_session or redirect "/"
    @card = BusBingo::Card.get(params[:id]) \
      or halt 404, 'Not Found'
    session.player == @card.player \
      or halt 403, 'Unauthorized'
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
    #puts(params)
    session = get_session or redirect "/"
    card = BusBingo::Card.get(params[:id]) \
      or halt 404, 'Not Found'
    session.player == @card.player \
      or halt 403, 'Unauthorized'
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
    send_file('lib/views/images/favicon.ico');
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
