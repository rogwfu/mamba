require 'zip/zip'

module Mamba
	class Population 
		include Enumerable 

		# Initialize the population by setting empty 
		def initialize()
			@chromosomes = Array.new()
			@fitness = 0.0
		end

		# Each method to satisfy Enumerable Module requirement
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

		# Remove chromosomes from the population
		def pop()
			removedChromosome = @chromosomes.pop()
			@fitness = @fitness - removedChromosome.fitness
			return(removedChromosome)
		end

		# Add chromosomes to the population based on a zipped file
		def seed!()

		end
	end
end
