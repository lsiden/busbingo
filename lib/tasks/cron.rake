require 'date'
require 'time'

class DateTime
  # Convert to seconds
  def to_i
    return self.hour * 60 * 60 + self.min * 60 + self.sec
  end
end
#puts DateTime::now.to_i

task :cron => :environment do
  if Time.now.hour % 24 == 0 # run every 24 hours
    puts "Deleting stale sessions over two hours old..."
    BusBingo::Session.all(:updated_at.to_i.gt => DateTime.now.to_i - (24 * 60 * 60)).each {|sess| sess.destroy }
  end
end
