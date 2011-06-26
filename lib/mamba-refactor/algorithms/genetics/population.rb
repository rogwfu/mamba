require 'bigdecimal'

module Mamba
	class Population 
		include Enumerable 

		# Initialize the population by setting empty 
		def initialize()
			@chromosomes = Array.new()
			@fitness = BigDecimal("0.0")
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
		end

		# Sum all the chromosome fitnesses
		def sum()
			@fitness = @chromosomes.inject(BigDecimal("0.0")) do |sum, chromosome|
				sum + chromosome.fitness
			end
		end

		# Add chromosomes to the population based on a zipped file
		def seed()

		end

		# Roulette wheel selection
		# (An Introduction to Genetic Algorithms - pg. 166)
		# @return [Chromosome] A chromosome proportionally selected by fitness
		def roulette()
			spinValue = random()
			rouletteValue = BigNumber("0.0")
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

		private

		# Generate a random value bounded by the population fitness
		# @return [BigDecimal] A random value 
		def random()
			randVal = 0.0

			# Note: Number conversion here BigDecimal => Float may cause issues
			begin
				srand(Time.now().to_i())
				randVal = rand(@fitness) + rand()
			end until randVal <= @fitness
			return(BigDecimal.new(randVal.to_s()))
		end
	end
end
