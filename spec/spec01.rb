$: << ::File.dirname(__FILE__) + '/lib'
require 'model'

describe BusBingo::Card, "#initialize" do
	it "creates a card with 25 tiles in random order" do
		card = BusBingo::Card.new
		card.tiles.count.should == 25
	end
end

describe BusBingo::Player, "#save" do
	it 'saves a new player with card and session' do
		player = BusBingo::Player.create(:id => "rufus", :email => "rufus@wufus.com")
		player.session = BusBingo::Session.new(:ip => "127.0.0.1")
		player.save

		session = player.session
		session.should be_saved
		session.player.should be_saved
		session.player.should == player

		session.player.card = BusBingo::Card.new
		session.player.save
		session.should be_saved
		session.player.should be_saved
		session.player.card.should be_saved
		session.player.card.id.should > 0
	end
end
