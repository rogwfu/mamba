require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'mamba-refactor/algorithms/genetics/population'
require 'mamba-refactor/algorithms/genetics/chromosome'

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

	it "should not allow an object with a class other than Chromosome to be added to the population" do
		lambda{@newPopulation.push(5)}.should raise_error
	end

	it "should allow appending a Chromosome to the population" do
		newChrom = Mamba::Chromosome.new()
		lambda{@newPopulation.push(newChrom)}.should_not raise_error
	end
	
	it "should append one chromosomes to the population and increase the populations size" do
		newChrom = Mamba::Chromosome.new()
		@newPopulation.push(newChrom)
		@newPopulation.instance_eval{@chromosomes.size()}.should == 1
	end

	it "should allow appending multiple chromosomes to the population" do
		newChrom = Mamba::Chromosome.new()
		newChrom2 = Mamba::Chromosome.new()
		newChrom3 = Mamba::Chromosome.new()
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		@newPopulation.instance_eval{@chromosomes.size()}.should == 3
	end

	it "when appending it should correctly add chromosome fitness to the populations fitness" do
		newChrom = Mamba::Chromosome.new(0,10.0)
		newChrom2 = Mamba::Chromosome.new(1,5.1)
		newChrom3 = Mamba::Chromosome.new(2,25.6)
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		@newPopulation.instance_eval{@fitness}.should == 40.7 
	end
end
