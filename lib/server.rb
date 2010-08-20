# Copyright Westside Consulting LLC, Ann Arbor, MI, USA, 2010
  
require 'rubygems'
require 'sinatra'
require 'json'
require 'digest/sha1'
require 'rest_client'
require 'helpers'
require 'pp'
require 'model'
require 'haml'
require 'rest_client'
require 'digest/sha1'
require 'maruku'
#require 'fileutils'

class Sinatra::Application

  # some configuration
  disable :dump_errors
  enable :logging

  helpers do
    include BusBingo::Helpers

    SESSION_COOKIE_NAME = 'x-busbingo-session-id'

    def set_long_expiration_header
      # set long expiration headers  
      one_year = 360 * 24 * 60 * 60 # a little less than a year for proxy's-sake
      time = Time.now + one_year
      time = time.to_time if time.respond_to?(:to_time)
      time = time.httpdate if time.respond_to?(:httpdate)
      response['Expires'] = time
      response['Cache-Control'] = "public, max-age=#{one_year}"
    end

    # Returns player with session.
    # Creates player if he does not already exist.
    def get_player_with_session(player_id, email)
      digest_id = Digest::SHA1.hexdigest(player_id) 
      player = BusBingo::Player.get(digest_id)
      
      if player.nil? then
        player = BusBingo::Player.create(:id => digest_id, :email => email)
        player.card = BusBingo::Card.new
      end
      player.session = BusBingo::Session.new(:ip => request.ip) \
        if !player.session
      player.save
      return player
    end

    # This session is different from env[rack.session].
    # It's maintained in the model.
    def get_session
      # Insure that caller has a session.
      session_id = request.cookies[SESSION_COOKIE_NAME]
      logger.debug "#{request.path}: session_id=#{session_id}"
      return nil unless session_id

      session = BusBingo::Session.get(session_id)
      session.save if session # reset :updated_at on session to note login
      logger.debug "get_session: session:"
			logger.debug session.pretty_inspect
      return session
    end
  end

  before do
    @copyright = 'Copyright&copy; 2010, Lawrence Siden, <a href="http://westside-consulting.com/">Westside Consulting LLC</a>, Ann Arbor, MI, USA'
    logger.debug request.path
    #logger.debug request.pretty_inspect

    if request.path != '/blackberry' \
      && request.env['HTTP_USER_AGENT'] =~ /blackberry/i then

      redirect '/blackberry'
    end
  end 

  # Over-ride obnoxious "Sinatra doesn't know this ditty..." page.
  not_found do
    throw :halt, [404, "Path not found: #{request.path}"]
  end

  ###############
  # Index page and login
  get '/' do
    redirect get_session ? '/play' : '/sign-in'
  end

  get '/sign-in' do
		# URL that rpxnow.com will post to after authenticating user credentials
		domain = localhost? ? 'localhost:9292' : 'busbingo.heroku.com'
		@token_url = uri_encode("http://#{domain}/sessions")
		haml :sign_in
  end

  get '/logout' do
    session = get_session or redirect "/"
    session.destroy
    redirect '/sign-in'
  end

  # Create new session for authenticated player.
  post '/sessions' do
    logger.debug "token=#{params[:token]}"
    json = RestClient.post('https://rpxnow.com/api/v2/auth_info',
                           :token => params[:token],
                           :apiKey => 'a684c5b0305f61508c906b4ca8da609a8ba3c257',
                           :format => 'json', :extended => 'true')
    auth_response = JSON.parse(json)
    logger.debug "post /sessions: auth_response:"
		logger.debug auth_response.pretty_inspect

    if auth_response['stat'] == 'ok' then
      profile = auth_response['profile']
      player_id = profile['identifier']
      email = profile['email']
      player = get_player_with_session(player_id, email)
      response.set_cookie(SESSION_COOKIE_NAME, {:value => player.session.id, :path => '/'})
      logger.debug "HTTP response=#{self.response.pretty_inspect}"
      redirect '/play'
    elsif err = auth_response['err'] then
      #throw :halt, [403, "Login failed; RPX auth_response #{err['code']}: #{err['msg']}"]
      logger.error "Login failed; RPX auth_response #{err['code']}: #{err['msg']}"
			redirect "/sign-in"
    else
      #throw :halt, [500, "Login failed; #{auth_response.pretty_inspect}"]
      logger.error "Login failed; #{auth_response.pretty_inspect}"
			redirect "/sign-in"
    end
  end

  get '/blackberry' do
    haml :blackberry
  end

  ###############
  # Tile management

=begin

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

  get '/count-tiles' do
    BusBingo::TileTemplate.count.to_s
  end

=end

  ###############
  # Mock page

=begin

  get '/mockup' do
    #FileUtils.pwd
    send_file('lib/views/mock.html')
  end

=end

  ###############
  # Games

  # Create a new card.
=begin
  post '/cards' do
    session = get_session or redirect "/"
    card = session.player.new_card
    redirect "http://#{request.host}:#{request.port}/play"
  end
=end

  # Render page with card card.
  # TODO - Replace this with '/card' or '/', id is in session
  #get '/cards/:id' do
  get '/play' do
    session = get_session or redirect "/"
		@card = session.player.card # Make card accessable to HAML
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
		card = session.player.card
		logger.debug "put #{request.path}: card.id=#{card.id}"
    params[:id].to_i == card.id \
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

  get '/about' do
    haml :about
  end

  get '/privacy' do
    haml :privacy
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

  # Everything else
  get '/*' do
    redirect '/play'
  end

  # Test that haml works
=begin
  get '/hello' do
    haml :hello
  end
=end
end
