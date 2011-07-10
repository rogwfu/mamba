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

	it "should be able to compare chromosomes (greater than) based on fitness" do
		newChrom = Mamba::Chromosome.new(0,10.0)
		newChrom2 = Mamba::Chromosome.new(1,5.1)
		result = newChrom > newChrom2
		result.should == true
	end

	it "should be able to compare chromosomes (greater than or equal) based on fitness" do
		newChrom = Mamba::Chromosome.new(0,10.0)
		newChrom2 = Mamba::Chromosome.new(1,10.0)
		result = newChrom >= newChrom2
		result.should == true
	end

	it "should be able to compare chromosomes (less than) based on fitness" do
		newChrom = Mamba::Chromosome.new(0,10.0)
		newChrom2 = Mamba::Chromosome.new(1,5.1)
		result = newChrom2 < newChrom
		result.should == true
	end
	it "should be able to compare chromosomes (less than or equal) based on fitness" do
		newChrom = Mamba::Chromosome.new(0,10.0)
		newChrom2 = Mamba::Chromosome.new(1,10.0)
		result = newChrom2 <= newChrom
		result.should == true
	end
	it "should be able to compare chromosomes (equal to) based on fitness" do
		newChrom = Mamba::Chromosome.new(0,10.0)
		newChrom2 = Mamba::Chromosome.new(1,10.0)
		result = newChrom == newChrom2
		result.should == true
	end
	it "should be able to compare chromosomes (spaceship operator) based on fitness" do
		newChrom = Mamba::Chromosome.new(0,10.0)
		newChrom2 = Mamba::Chromosome.new(1,5.1)
		result = newChrom2 <=> newChrom
		result.should == -1
	end

end
