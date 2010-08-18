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
require 'helpers'
require 'permutation'
#require 'dm-types'
#require 'set'
#require 'pp'

include BusBingo::Helpers

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3:busbingo.db')

DataMapper::Model.raise_on_save_failure = true

# Override definition in dm-core / lib / dm-core / resource.rb
# http://github.com/datamapper/dm-core/blob/master/lib/dm-core/resource.rb
module DataMapper
  module Resource

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
		property	:name, String, :key => true
		property	:desc, Text
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
    N_TILES = N_ROWS * N_COLS

    def tileAt(row, col)
      self.tiles[row.to_i * N_COLS + col.to_i]
    end

    def has_bingo?(row=nil, col=nil)
      BingoLogic::BingoCard.new(self.rawdata).has_bingo?(row, col)
    end

    def initialize(*a)
      BusBingo::TileTemplate.count > 0 \
        or raise "Cannot create new card; there are no tiles defined"

      super
      all_templates = BusBingo::TileTemplate.all #(:enabled => true) # does not work in SqlLite
      selected_templates = []

      while selected_templates.length < N_TILES do
        # Shake the coffee-can and select more tiles.
        selected_templates += Permutation.for(all_templates).random!.project(all_templates)
      end
      self.tiles = selected_templates[0, N_TILES].map {|tt| BusBingo::Tile.new(:tile_template => tt)}
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
      self.id = Digest::SHA1.hexdigest(ip + Time.now.to_s)
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

if localhost? then
	DataMapper.auto_migrate!  # for testing - will destroy any existing data!
	load File.dirname(__FILE__) + "/../scripts/insert-tiles.rb"
else
	DataMapper.auto_upgrade! # for production
end
