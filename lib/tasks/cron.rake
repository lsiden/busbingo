task :cron => :environment do
  if Time.now.hour % 24 == 0 # run every 24 hours
    puts "Deleting stale sessions over two hours old..."
    BusBingo.Session(:updated_at.gt => Time.now - (24 * 60 * 60)).each {|sess| sess.destroy }
  end
end
