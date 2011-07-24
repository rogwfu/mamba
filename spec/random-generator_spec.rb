require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'mamba-refactor/fuzzrnd'

describe "RandomGenerator" do

	#
	# Create a new generator for each test
	#
	before :each do
		@rgenerator = Mamba::RandomGenerator.new()
	end

	it "should generate bytes equal to the parameter given" do
		bytes = @rgenerator.bytes(10)
		bytes.length.should == 10
	end

	it "should generate unique bytes" do
		bytes = @rgenerator.bytes(10)
		bytes2 = @rgenerator.bytes(10)
		bytes3 = @rgenerator.bytes(10)

		bytes.should_not == bytes2
		bytes.should_not == bytes3
		bytes2.should_not == bytes3
	end
end
