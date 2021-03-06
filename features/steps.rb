Given /^the following board$/ do |table|
  # table is a Cucumber::Ast::Table
  @data = table.raw
end

Then /^I count (\d+) covered squares$/ do |count|
  (@data.flatten.inject(0) {|sum, token| sum + (token == 'x' ? 1 : 0)} ).should == count.to_i
end

Then /^I do not have bingo$/ do
  card = BingoLogic::BingoCard.new(@data)
  card.has_bingo?.should_not be_true
end

Then /^I do have bingo$/ do
  card = BingoLogic::BingoCard.new(@data)
  card.has_bingo?.should be_true
end

When /^the last tile covered was \((\d), (\d)\)$/ do |row, col|
  @row = row
  @col = col
end
