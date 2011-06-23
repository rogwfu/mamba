require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'mamba-refactor/algorithms/genetics/chromosome'

describe "PopulationMember" do
	before :each do
		@newChromosome = Mamba::Chromosome.new()
	end

	it "should contain an id initialize to 0" do
		@newChromosome.id.should == 0
	end

	it "should contain a fitness value initialized to 0" do
		@newChromosome.fitness.should == 0
	end

end
