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
		card.tiles = Permutation.for(tileTemplates).random!.project(tileTemplates)[0, 25] \
      .map {|tt| BusBingo::Tile.new(:tile_template => tt)}
		card.player = BusBingo::Player.new # TODO - Player should be available from session
		lambda{card.save}.should_not raise_error
  end
end
