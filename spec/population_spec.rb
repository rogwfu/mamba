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
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		@newPopulation.instance_eval{@fitness}.should == 40.7 
	end

	it "should remove a chromosome from the end of the population" do
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		@newPopulation.pop()
		@newPopulation.instance_eval{@chromosomes.size()}.should == 2 
	end

	it "should correctly remove a chromosome from the end of the population" do
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		removedChrom = @newPopulation.pop()
		removedChrom.id.should == 2
	end

	it "should decrement population fitness when a chromosome is removed from the end of the population" do
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		@newPopulation.pop()
		@newPopulation.instance_eval{@fitness}.should == 15.1
	end

	it "should handle popping a chromosome if the population is empty" do
		removedChrom = @newPopulation.pop()
		removedChrom.should == nil
	end

	it "should be able to determine the maximumally fit chromosome in the population" do
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		maxFitChrom = @newPopulation.max()
		maxFitChrom.fitness.should == 25.6
	end

	it "should be able to clean up a population by removing all chromosomes and resetting fitness" do
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		@newPopulation.clear()
		@newPopulation.instance_eval{@fitness}.should == 0.0 
		@newPopulation.instance_eval{@chromosomes.size()}.should == 0
	end

	it "should generate a random number less than the population fitness" do
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		randVal = @newPopulation.instance_eval{random()}
		@newPopulation.instance_eval{@fitness}.should >= randVal 
	end

	it "should be capable of summing chromosome fitnesses to get population fitness" do
		newChrom = Mamba::Chromosome.new(0,"10.0")
		newChrom2 = Mamba::Chromosome.new(1,"5.1")
		newChrom3 = Mamba::Chromosome.new(2,"25.6")
		@newPopulation.push(newChrom, newChrom2, newChrom3)
		@newPopulation.instance_eval{@fitness = BigDecimal("0")}
		@newPopulation.sum()
		@newPopulation.instance_eval{@fitness}.should == 40.7
	end
end
