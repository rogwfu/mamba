require 'bigdecimal'

module Mamba
	class Population 
		include Enumerable 
		attr_reader		:fitness
		attr_reader		:fittestChromosome

		# Initialize the population by setting empty 
		def initialize()
			@chromosomes = Array.new()
			@fitness = BigDecimal("0.0")
			@fittestChromosome = nil
			#srand(Time.now().to_i())
		end

		# Each method to satisfy Enumerable Module requirement
		# @param [Proc] A block of code to call with each element as an argument
		def each(&block)
			# Call the block given with each chromosome as an argument
			 @chromosomes.each do |chromosome| 
				 block.call(chromosome)
			end
		end

		# Add chromosomes to the end of the population of chromosomes
		# @param [Array] a set of chromsomes to add to the population
		def push(*chromosomes)
			#
			# Add all new chromosomes to the existing chromosome population 
			# 
			chromosomes.each do |newChromosome|
				#
				# Error check type to ensure new chromosomes
				#
				if(!newChromosome.class.eql?(Mamba::Chromosome)) then
					raise "Invalid object appended to population" 
				end
			end

			#
			# If all objects sane, add to the population
			#
			@chromosomes = @chromosomes + chromosomes 
			@fitness = chromosomes.inject(@fitness) do |sum, chromosome|
				sum + chromosome.fitness
			end
		end

		# Remove last chromosome from the population of chromosomes
		# @return [Chromosome] A Chromosome removed from the end of the population
		def pop()
			removedChromosome = @chromosomes.pop()
			@fitness = @fitness - removedChromosome.fitness unless !removedChromosome
			return(removedChromosome)
		end

		# Clear the population and reset population fitness
		def clear()
			@chromosomes.clear()
			@fitness = BigDecimal("0.0")
			@fittestChromosome = nil
		end

		# Sum all the chromosome fitnesses
		def sum()
			@fitness = @chromosomes.inject(BigDecimal("0.0")) do |sum, chromosome|
				sum + chromosome.fitness
			end
		end

		# Maximum chromosome in the current population
		def max()
			@fittestChromosome = super()
		end

		# Roulette wheel selection
		# (An Introduction to Genetic Algorithms - pg. 166)
		# @return [Chromosome] A chromosome proportionally selected by fitness
		def roulette()
			spinValue = randomValue()
			rouletteValue = BigDecimal("0.0")
			@chromosomes.each do |chromosome|
				rouletteValue += chromosome.fitness

				if(rouletteValue >= spinValue) then
					return(chromosome)
				end
			end

			#
			# Saftey, Return last element
			#
			return(@chromosomes[-1])
		end

		# For the CHC algorithm (no bias of chromosome fitness)
		# @return [Chromosome] A randomly selected chromosome
		def random()
			if(size() > 0) then
				return(@chromosomes[rand(size())])
			else
				return nil
			end
		end

		# Convenience method for printing a population
		# @return [String] A string representation of the population object
		def to_s()
			@chromosomes
			string = "#{self.class} (#{self.__id__}): Fitness: #{@fitness.to_s('F')}\n"
			@chromosomes.each do |chromosome|
				string << chromosome.to_s() + "\n"
			end

			return(string)
		end

		# @return [Integer] the size of the population array
		def size()
			@chromosomes.size()
		end

		private

		# Generate a random value bounded by the population fitness
		# @return [BigDecimal] A random value 
		def randomValue()
			randVal = 0.0

			# Error case for fitness being zero
			if(@fitness == BigDecimal("0.0")) then
				return(BigDecimal("0.0"))
			end

			# Note: Number conversion here BigDecimal => Float may cause issues
			prand = Random.new()
			begin
				#randVal = prand.rand(@fitness.to_f()) + prand.rand(@fitness.to_f())
				randVal = prand.rand(@fitness.to_f())
			end until randVal <= @fitness
			return(BigDecimal.new(randVal.to_s()))
		end
	end
end
