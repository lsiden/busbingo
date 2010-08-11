# Copyright Westside Consulting LLC, Ann Arbor, MI, USA, 2010

require 'rubygems'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-is-list'
require 'dm-timestamps'
#require 'dm-types'
require 'dm-validations'
#require 'json'
#require 'set'
#require 'pp'
#require 'digest/sha1'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3:busbingo.db')

DataMapper::Model.raise_on_save_failure = true

# Override definition in dm-core / lib / dm-core / resource.rb
# http://github.com/datamapper/dm-core/blob/master/lib/dm-core/resource.rb
module DataMapper
  module Resource
    def assert_save_successful(method, save_retval)
      if save_retval != true && raise_on_save_failure
        raise SaveFailureError.new("#{model}##{method}" \
                                   + "\n#{self.errors.pretty_inspect}" \
                                   + "\n#{model} was not saved", self.pretty_inspect)
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
  end

	class Player
		include DataMapper::Resource
		property	:id, Serial
		property	:email, String
	end
end

DataMapper.finalize

# TODO
DataMapper.auto_upgrade! # for production
#DataMapper.auto_migrate!  # for testing - will destroy any existing data!
