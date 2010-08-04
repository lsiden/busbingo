require 'pp'

Given /^the following board$/ do |table|
  # table is a Cucumber::Ast::Table
  @data = table.raw
end

@zero
Then /^I count 0 covered squares$/ do
  count = @data.flatten.inject(0) {|sum, token| sum + (token == 'x' ? 1 : 0)}
  count.should == 0
end

Then /^I do not have bingo$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I count 12 covered squares$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I count 14 covered squares$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I do have bingo$/ do
  pending # express the regexp above with the code you wish you had
end

