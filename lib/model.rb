# Copyright Westside Consulting LLC, Ann Arbor, MI, USA, 2010

require 'rubygems'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-is-list'
require 'dm-timestamps'
require 'dm-validations'
require 'bingoLogic'
require 'json'
require 'digest/sha1'
require 'bb_logger'
require 'permutation'
#require 'dm-types'
#require 'set'
#require 'pp'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3:busbingo.db')

DataMapper::Model.raise_on_save_failure = true

# Override definition in dm-core / lib / dm-core / resource.rb
# http://github.com/datamapper/dm-core/blob/master/lib/dm-core/resource.rb
module DataMapper
  module Resource
    include BusBingo

    alias_method :orig_save, :save

    def save(*a)
      self.errors.each {|e| logger.warn e} if (!self.valid?)
      orig_save(*a)
    end

    def assert_save_successful(method, save_retval)
      if save_retval != true && raise_on_save_failure then
        self.errors.each {|e| logger.debug e}
        logger.debug self.pretty_inspect
        raise SaveFailureError.new("#{model} was not saved", self)
      end
    end
  end
end

module BusBingo
	class TileTemplate
		include DataMapper::Resource
		property	:id, Serial
		property	:title, String
		property	:alt, String
		property	:image_filename, String		# name of image file without pathname
		property	:enabled?, Boolean				# whether to include this image in new cards

    has n,    :tiles
	end

	class Tile
		include DataMapper::Resource
		property	:id, Serial
		property	:covered?, Boolean				# whether this tile on the card is covered
		property	:updated_at, DateTime

    belongs_to  :tile_template
    belongs_to  :card
    is :list, :scope => :card_id
	end

  class Card
		include DataMapper::Resource
    property    :id, Serial
		property		:created_at, DateTime

    belongs_to  :player
    has n,      :tiles  # always 25 for a 5 x 5 card

    N_ROWS = 5
    N_COLS = 5

    def tileAt(row, col)
      self.tiles[row.to_i * N_COLS + col.to_i]
    end

    def has_bingo?(row=nil, col=nil)
      BingoLogic::BingoCard.new(self.rawdata).has_bingo?(row, col)
    end

    def initialize
      BusBingo::TileTemplate.count > 0 \
        or raise "Cannot create new card; there are no tiles defined"

      nTiles = BusBingo::Card::N_ROWS * BusBingo::Card::N_COLS
      tileTemplates = []

      while tileTemplates.length < nTiles do
        #tileTemplates += BusBingo::TileTemplate.all(:enabled => true) # does not work with SqlLite
        tileTemplates += BusBingo::TileTemplate.all
      end
      self.tiles = Permutation.for(tileTemplates).random! \
        .project(tileTemplates)[0, nTiles] \
        .map {|tt| BusBingo::Tile.new(:tile_template => tt)}
    end

    protected

    def rawdata
      (0..BusBingo::Card::N_ROWS-1).map do |i|
        self.rowAt(i).map {|tile| tile.covered?}
      end
    end

    # Return an entire row as an array
    def rowAt(row)
      self.tiles[row.to_i * N_COLS, N_COLS]
    end
 
  end

  class Session
    include DataMapper::Resource

    property    :id, String, :key => true
    property    :ip, String, :index => true
    timestamps  :updated_at # for timing-out

    belongs_to  :player

    def initialize(attrs)
      ip = attrs[:ip]

      # Destroy previous sessions for same player and ip
      #self.class.all({:player => player}).each {|s| s.destroy}
      self.class.all({:ip => ip}).each {|s| s.destroy}

      attrs[:id] = Digest::SHA1.hexdigest(ip + Time.now.to_s)
      super attrs
    end
  end

	class Player
		include DataMapper::Resource
		property	:id, String, :key => true # OpenID URL
		property	:email, String

    has 1,    :card
    has 1,    :session
  end
end

DataMapper.finalize

require 'socket'
require 'set'

hostname = Socket.gethostname

if %w(morpheus lsiden-laptop).to_set.include?(hostname) then
	DataMapper.auto_migrate!  # for testing - will destroy any existing data!
	load File.dirname(__FILE__) + "/../scripts/insert-tiles.rb"
else
	DataMapper.auto_upgrade! # for production
end
