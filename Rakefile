$: << ::File.dirname(__FILE__) + '/lib'
require 'model'

task :cron do
  if Time.now.hour % 24 == 0 # run every two hours
    puts "Deleting stale sessions over twenty-four hours old..."
    BusBingo::Session.all(:updated_at.lt => Time.now - (24 * 60 * 60)).each {|sess| sess.destroy }
  end
end
