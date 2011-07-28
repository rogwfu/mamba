require 'amatch'

module Mamba
	module Algorithms
		module Helpers
			module CHC
				INCEST_PREVENTION_INITIAL_THRESHOLD = 0.25

				# Metaprogramming for additional options to GA Configuration Hash
				def self.included(base)
					class << base
						def generate_config()
							self.superclass.generate_config do |gaConfig|
								# Delete unused rates from the genetic algorithm's configuration
								gaConfig.delete("Mutation Rate")
								gaConfig.delete("Crossover Rate")

								# Starting incest prevention factor (Historical Initial Threshold)
								gaConfig["Incest Prevention"] = INCEST_PREVENTION_INITIAL_THRESHOLD
							end
						end
					end
				end

				def evolve() 
					incestThreshold = calculate_incest_prevention()
					0.step(@simpleGAConfig['Population Size']-1, 1) do |childID|
						# Append candidate to the name
						childID = childID.to_s() + "c"

						# Randomly select parents
						parents, child = open_parents_and_children(childID, "random")

						# Perform crossover based on incest threshold
						uniform_crossover(parents, childID, child, incestThreshold)
					end

					# Cleanup the mess from this population
#					cleanup()

					# Hack for right now
#					@simpleGAConfig['Population Size'] = @testSetMappings.size() 
					@logger.info("Temporary test set mapping: #{@temporaryMappings.inspect()}")
					# Test the fitness of the intermediate children
					@temporaryMappings.each do |key, value|
						@executor.run(@logger, value) 
						fitness = rand(25).to_s()
						@population.push(Chromosome.new("#{key}", fitness))
						@reporter.numCasesRun = @reporter.numCasesRun + 1
					end

					# Sort the combined array
					@logger.info(@population.inspect)
					@population.sort!
					@logger.info(@population.inspect)

					exit(1)
				end

				# Calculate incest prevention measurement
				# @returns [Fixnum] Incest prevention measure for the current population (Number of bytes required to be different)
				def calculate_incest_prevention()
					largestChromosomeSize = 0
					@testSetMappings.each_value do |testFile|
						chromosomeSize = File.size?(testFile)
						if(chromosomeSize > largestChromosomeSize) then
							largestChromosomeSize = chromosomeSize
						end
					end

					# Average Chromosome Length * Incest Prevention Measure
					currentIncestThreshold = (largestChromosomeSize/@testSetMappings.size()) *  @simpleGAConfig["Incest Prevention"]

					@logger.info("Largest File size is: #{largestChromosomeSize}")
					@logger.info("Average File size is: #{largestChromosomeSize/@testSetMappings.size()}")
					@logger.info("Incest Prevention should be: #{currentIncestThreshold}")

					return(currentIncestThreshold)
				end

				# Function to compose new filenames for children of the next generation
				# c for a candidate child?
				# @param [Fixnum] The current child number being generated
				# @param [String] The selection method for the parents
				# @returns [Array, String] Opens File descriptors for parents and children  
				def open_parents_and_children(childID, selectionMethod="roulette")
					parents = Array.new()

					2.times do
						parents << File.open(@testSetMappings[@population.send(selectionMethod.to_sym()).id], "rb") 
					end

					@logger.info("In open function: " + parents.inspect())
					child = "tests" + File::SEPARATOR + "#{@nextGenerationNumber}."  + "#{childID}." + parents[0].path.split(".")[-1] 
					@logger.info("In open children: " + child.inspect())

					return [parents, child]
				end

				# Half Uniform crossover (HUX) with incest prevention
				# @param [Array] Array of parent file descriptors 
				# @param [Fixnum] The current child number being generated
				# @param [String] Child Filename 
				# @param [Fixnum] Number bytes parents must differ before than can mate
				def uniform_crossover(parents, childID, child, incestThreshold)

					# Calculate the hamming distance between the parents
					hamming = Amatch::Hamming.new(parents[0].read())
					hammingDistance = hamming.match(parents[1].read())

					@logger.info("Hamming distance is: #{hammingDistance}")
					if(hammingDistance >= incestThreshold) then
						@logger.info("Greater than threshold")
						@logger.info("Copying: #{parents[0].path} to #{child}")
						FileUtils.cp(parents[0].path, child) 
						@temporaryMappings[childID] = child 
					end
					# Cleanup filename arrays
					parents.each { |parent| parent.close()}
					parents.clear()

					#	- Incest prevention
					#		- Calculate the hamming distance between the two chromosomes
					#		- If parents differ by L/4, where L = length of the strings in bits, then mate (mating threshold "incest prevention")
					#	- If no offspring are inserted into the population then the threshold is reduced by 1 (need to reinvent this for my situation)

					# uniform crossover half the bits "that differ between the two parents"
					#	- find all the bit positions that differ between the two parents
					#	- randomly select a position and swap the bits
					#	- repeat this process until half of the differing bits have been swapped
					#
					# No mutation is applied during recombination
					# Detect when Difference threshold (L/4) has dropped to zero and no new offspring generated, then go into cataclysmic mutation
				end

				# Reinitialize the population 
				def cataclysimic_mutation()
					# Copy the best chromosome over to the new population
					# Remaining elements are formed by a random mutation of about 35% of the bits in the best element?
				end
			end
		end
	end
end
