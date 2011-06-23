require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'mamba-refactor/algorithms/genetics/population'

describe "Population" do
	before :each do
		@newPopulation = Mamba::Population.new()
	end

	it "should contain a fitness value initialized to 0" do
		@newPopulation.instance_eval{ @fitness}.should == 0
	end

	it "should contain an empty array of population memebers when initialized" do
		@newPopulation.instance_eval{@chromosomes.size()}.should == 0
	end
end
