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
require 'maruku'
#require 'fileutils'

class Sinatra::Application

  # some configuration
  disable :dump_errors
  enable :logging

  helpers do
    include BusBingo::Helpers

    SESSION_COOKIE_NAME = 'x-busbingo-session-id'
    ADMIN_SESSION_ID = '59f219d4c14b40925f43a3b0a001b4e9eb174c41'
    ADMIN_PASSWORD = 't@keth3Bus!'
    LOCAL_DOMAIN = 'localhost:5000' 
    HOSTED_DOMAIN = 'busbingo.heroku.com'

    def redirect_lost_player
      if get_session then
        redirect '/play'
      else
        redirect '/sign-in'
      end
    end

    def redirect_lost_admin
      if request.cookies[SESSION_COOKIE_NAME] == ADMIN_SESSION_ID then
        redirect '/admin/winners'
      else
        redirect '/admin/login'
      end
    end 

    def display_winners
      request.cookies[SESSION_COOKIE_NAME] == ADMIN_SESSION_ID \
        or redirect '/admin/login'

      @winners = BusBingo::Player.select {|p| p.can_receive_prize? && p.card.has_bingo? }
      haml :winners
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
      session_id = request.cookies[SESSION_COOKIE_NAME] \
        or return nil

      session = BusBingo::Session.get(session_id) \
        or return nil # timed out

      session.save if session # reset :updated_at on session to prevent it from being deleted by cron
      return session
    end

    def html_head(attrs)
      @html_head = <<-XXX
      <head>
        <meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
        <meta http-equiv="content-script-type" content="text/javascript" />
        <title>#{attrs[:title]}</title>
        <script type="text/javascript" src="/views/js/jquery-1.4.2.min.js"></script>
        <script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
        <script type="text/javascript" src="/views/js/script.js"></script>
        <link rel="stylesheet" href="/views/style.css" type="text/css" media="all" />
      </head>
      XXX
    end

    class Menu
      attr_reader :items
     
      def initialize(env)
       @items = {
        :credits    => {:href => '/credits', :content => 'Credits'},
        :about_me => {:href => '/about-me', :content => 'About Me'},
        :privacy  => {:href => '/privacy', :content => 'Privacy'},
        :play     => {:href => '/play', :content => 'Play!'},
        :print    => {:href => 'javascript: window.print();', :content => 'Print'},
        :logout   => {:href => '/logout', :content => 'Logout'},
        :how_to_play => {:href => '/how-to-play', :content => 'How to Play'},
        :legend   => {:href => '/legend', :content => 'Key to Images'},
        }
        @env = env
      end

      # === Parameters
      # * *items - symbols that indicate which items to include
      # === Example
      #   render(:credits, :privacy)
      def render(*items)
        if smart_phone? then
          s = "<select onchange='window.location = this.value'>\n<option>Go to</option>\n"
          items.each do |sym|
            item = @items[sym]
            s += %Q(<option value="#{item[:href]}">#{item[:content]}</option>\n)
          end
          s += "</select>\n"
        else
          s = "<ul>\n"
          items.each do |sym|
            item = @items[sym]
            s += %Q(<li><a href="#{item[:href]}">#{item[:content]}</a></li>\n)
          end
          s += "</ul>\n"
        end
        return s
      end
    end
  end

  before do
    @menu = Menu.new(env)
    @copyright = 'Copyright&copy; 2010, Lawrence Siden, <a href="http://westside-consulting.com/">Westside Consulting LLC</a>, Ann Arbor, MI, USA'
    @follow = <<-XXX
      <div><a href="http://twitter.com/share" class="twitter-share-button" data-count="none" data-via="getdowntown">Tweet</a></div>
      <div><fb:like href="busbingo.heroku.com" width="150"></fb:like></div>
    XXX
    @facebook_sdk = <<-XXX
      <div id="fb-root"></div>
      <script>
        window.fbAsyncInit = function() {
          FB.init({appId: 'your app id', status: true, cookie: true,
                   xfbml: true});
        };
        (function() {
          var e = document.createElement('script'); e.async = true;
          e.src = document.location.protocol +
            '//connect.facebook.net/en_US/all.js';
          document.getElementById('fb-root').appendChild(e);
        }());
      </script>
    XXX
    logger.debug request.pretty_inspect

    redirect '/blackberry' \
      if request.env['HTTP_USER_AGENT'] =~ /blackberry/i && request.path =~ /^\/sign-in/
  end 

  # Over-ride obnoxious "Sinatra doesn't know this ditty..." page.
  not_found do
    throw :halt, [404, "Path not found: #{request.path}"]
  end

  ###############
  # Sign in

  get '/sign-in' do
    redirect '/play' \
      if get_session

    # URL that rpxnow.com will post to after authenticating user credentials
    domain = localhost? ? LOCAL_DOMAIN : HOSTED_DOMAIN

    #@token_url = uri_encode("http://#{domain}/sessions")
    @token_url = "http://#{domain}/sessions"
    haml :sign_in
  end

  get '/logout' do
    if session = get_session then
      session.destroy
    end
    redirect '/sign-in'
  end

  get '/about-me' do
    session = get_session \
      or redirect '/sign-in'

    @player = session.player
    haml :about_me
  end

  post '/about-me' do
    session = get_session \
      or redirect '/sign-in'

    session.player.update(:email => params[:email], :gopass => params[:gopass])
    redirect '/play'
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
		logger.debug "auth_response['stat']=#{auth_response['stat']}"

    if auth_response['stat'] == 'ok' then
      profile = auth_response['profile']
      player_id = profile['identifier']
      email = profile['email']
      player = get_player_with_session(player_id, email)
      response.set_cookie(SESSION_COOKIE_NAME, {:value => player.session.id, :path => '/'})
      logger.debug "HTTP response=#{self.response.pretty_inspect}"
      redirect player.can_receive_prize? ? '/play' : '/about-me'
    elsif err = auth_response['err'] then
      #throw :halt, [403, "Login failed; RPX auth_response #{err['code']}: #{err['msg']}"]
      logger.error "Login failed; RPX auth_response #{err['code']}: #{err['msg']}"
    else
      #throw :halt, [500, "Login failed; #{auth_response.pretty_inspect}"]
      logger.error "Login failed; #{auth_response.pretty_inspect}"
    end
    redirect '/sign-in'
  end

  get '/blackberry' do
    haml :blackberry
  end

=begin
  ###############
  # Tile management

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

  # Render page with card card.
  get '/play' do
    session = get_session \
      or redirect '/sign-in'
		@card = session.player.card # Make card accessable to HAML
    haml :play
  end

  # For card :id, set <row, col> to state {0 = uncovered, anything else is covered}.
  # Returns header with x-busbingo-has-bingo that matches /'[x ]{nTiles}'(, winner)?/
  put '/cards/:id' do
    #puts(params)
    session = get_session \
      or redirect '/sign-in'
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

  get '/credits' do
    haml :credits
  end

  get '/privacy' do
    haml :privacy
  end

  get '/how-to-play' do
    haml :how_to_play
  end

  get '/legend' do
    @tile_templates = BusBingo::TileTemplate.all
    haml :legend
  end

  get '/views/*' do
    path = params[:splat].first.split('/')
    path = File.join('lib/views', *path)
    path = File.join(path, 'index.html') if File.directory?(path)
    #logger.debug(path)
    send_file(path)
  end

  #################
  # Admin

  get '/admin/login' do
    request.cookies[SESSION_COOKIE_NAME] != ADMIN_SESSION_ID \
      or redirect '/admin'

    haml :admin_login
  end

  post '/admin/login' do
    params[:password] == ADMIN_PASSWORD \
      or redirect '/admin/login?try_again=1'

    response.set_cookie(SESSION_COOKIE_NAME, {:value => ADMIN_SESSION_ID, :path => '/'})
    redirect '/admin'
  end

  get '/admin/winners' do
    display_winners
  end

  get '/admin' do
    display_winners
  end

  get '/admin/*' do
    redirect_lost_admin
  end

  #################
  # Everything else

  # 'index' page
  get '/' do
    redirect_lost_player
  end

  get '/*' do
    redirect_lost_player
  end

  # Test that haml works
=begin
  get '/hello' do
    haml :hello
  end
=end
end
