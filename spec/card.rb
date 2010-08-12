require 'permutation'
require 'pp'
require File.dirname(__FILE__) + '/../lib/model.rb'

describe BusBingo::Card do

  it "is composed of 25 random tiles" do
		card = BusBingo::Card.new
		#tileTemplates = BusBingo::TileTemplate.all(:enabled => true) # does not work with SqlLite
		tileTemplates = []
    while tileTemplates.length < 25 do
      tileTemplates += BusBingo::TileTemplate.all.to_a
    end
    perm = Permutation.new(tileTemplates.length)
		card.tiles = perm.random!.value[0, 25].map{|i| BusBingo::Tile.new(:tile_template => tileTemplates[i])}
		card.player = BusBingo::Player.new # TODO - Player should be available from session
		card.save

  end

end
