#web: bundle exec rackup config.ru -p $PORT
web: thin -p $PORT -e $RACK_ENV -R $HEROKU_RACK start
