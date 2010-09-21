task :cron do
  if Time.now.hour % 2 == 0 # run every two hours
    puts "Deleting stale sessions over two hours old..."
    BusBingo.Session(:updated_at.gt => Time.now - (2 * 60 * 60)).each {|sess| sess.destroy }
  end
end
