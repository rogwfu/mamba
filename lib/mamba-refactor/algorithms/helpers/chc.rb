require 'amatch'

module Mamba
	module Algorithms
		module Helpers
			module CHC
				INCEST_PREVENTION_INITIAL_THRESHOLD = 0.25
				MINIMUM_INCEST_PREVENTION_THRESHOLD = 0.05

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

					until (@temporaryMappings.size > 0 or @simpleGAConfig['Incest Prevention'] <= MINIMUM_INCEST_PREVENTION_THRESHOLD) do
						0.step(@simpleGAConfig['Population Size']-1, 1) do |childID|
							# Append candidate to the name
							childID = childID.to_s() + "c"

							# Randomly select parents
							parents, child = open_parents_and_children(childID, "random")

							# Perform crossover based on incest threshold
							uniform_crossover(parents, childID, child, incestThreshold)
						end

						# Check for decrementing the incest prevention
						if(@temporaryMappings.size == 0) then
							@simpleGAConfig['Incest Prevention'] = @simpleGAConfig['Incest Prevention'] * 0.50
							@logger.info("Decrementing incest prevention threshold to: #{@simpleGAConfig['Incest Prevention']}")
						end
					end

					# Check for cataclysmic mutation
					if(@simpleGAConfig['Incest Prevention'] <= MINIMUM_INCEST_PREVENTION_THRESHOLD) then
						cataclysimic_mutation()
					else

						evaluate_intermediate_children()

						# Sort the combined array
						@logger.info(@population.inspect)
						@sorted_population = @population.sort()
						@logger.info(@sorted_population.inspect)
						@logger.info("Sorted array size: #{@sorted_population.size()}")

						spawn_new_generation()
					end

					cleanup()
				end

				def evaluate_intermediate_children()
					# Test the fitness of the intermediate children
					@temporaryMappings.each do |key, value|
						@executor.run(@logger, value) 
						fitness = rand(25).to_s()
						@population.push(Chromosome.new("#{key}", fitness))
						@reporter.numCasesRun = @reporter.numCasesRun + 1
					end

					# Evaluated the candidate chromosomes, so cleanup the mapping
					@temporaryMappings.clear()
				end

				def spawn_new_generation()
					# Sorted now, so copy over to the temporary mappings (renumber), copy files over, and good to go
					@simpleGAConfig['Population Size'].times do |tim|
						filename1 = "tests" + File::SEPARATOR + "#{@nextGenerationNumber - 1}.#{@sorted_population[@sorted_population.size() - 1 - tim].id}." + @testSetMappings[0].split(".")[-1] 
						filename2 = "tests" + File::SEPARATOR + "#{@nextGenerationNumber}.#{tim}." + @testSetMappings[0].split(".")[-1] 
						FileUtils.cp(filename1, filename2) 
						@temporaryMappings[tim] = filename2 
					end
				end

				# Calculate incest prevention measurement
				# @returns [Fixnum] Incest prevention measure for the current population (Number of bytes required to be different)
				def calculate_incest_prevention()
					largestChromosomeSize = 0
					@testSetMappings.each_value do |testFile|
						@logger.info("Incest prevention: #{testFile}")
						chromosomeSize = File.size?(testFile)
						if(chromosomeSize == nil) then
							@logger.info("This doesn't exist: #{testFile}")
						end
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
					child = "tests" + File::SEPARATOR + "#{@nextGenerationNumber - 1}."  + "#{childID}." + parents[0].path.split(".")[-1] 
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
					parents.each { |parent| parent.rewind()}

					@logger.info("Hamming distance is: #{hammingDistance}")
					if(hammingDistance >= incestThreshold) then
						
						@logger.info("Greater than threshold")
						@logger.info("Copying: #{parents[0].path} to #{child}")
#						FileUtils.cp(parents[0].path, child) 
						# Use the smaller parent to limit crawl to infinity
						childSize = parents[0].size()
						if(parents[0].size() > parents[1].size)  then
							childSize = parents[1].size
						end

						@logger.info("Child Size is: #{childSize}")

						File.open(child, "w+b") do |childFD| 
							0.upto(childSize) do
								if(rand() < 0.002) then
									childFD.write(parents[0].read(1))
									parents[1].read(1)
								else
									childFD.write(parents[1].read(1))
									parents[0].read(1)
								end
							end
						end

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
					@logger.info("In the cataclysimic_mutation")

					# Calculate population mix
					fittestChromosome = @testSetMappings[@population.max().id]
					numberToMutate = (@simpleGAConfig['Population Size'] * 0.35).floor()

					# Copy the fittest chromosome
					filename = "tests" + File::SEPARATOR + "#{@nextGenerationNumber}.0." + @testSetMappings[0].split(".")[-1] 
					FileUtils.cp(fittestChromosome, filename) 
					@temporaryMappings[0] = filename 

					# Mutate a percentage of the new population (based on fittest chromosome)
					mutate(fittestChromosome, numberToMutate)

					# Seed the rest with random members of the initial population 
					(numberToMutate + 1).upto(@simpleGAConfig['Population Size']-1) do |chromosomeID|
						@logger.info("Copying over chromosome number: #{chromosomeID}")
						initialChromosome = rand(@simpleGAConfig['Population Size'])
						oldChromosomeFilename = "tests" + File::SEPARATOR + "0.#{initialChromosome}." + fittestChromosome.split(".")[-1]
						newChromosomeFilename = "tests" + File::SEPARATOR + "#{@nextGenerationNumber}.#{chromosomeID}." + fittestChromosome.split(".")[-1]
						FileUtils.cp(oldChromosomeFilename, newChromosomeFilename) 
						@temporaryMappings[chromosomeID] = newChromosomeFilename
					end

					# Reset threshold
					@simpleGAConfig["Incest Prevention"] = INCEST_PREVENTION_INITIAL_THRESHOLD

					# Increment restart counter, check if we need to stop it
				end

				# Mutate a percentage of the new population
				# @param [String] Filename of the current fittest chromosome
				# @param [Fixnum] The number of chromosomes to mutate (Base chromosome is the fittest chromosome)
				def mutate(fittestChromosome, numberToMutate)
					1.upto(numberToMutate) do |chromosomeID|
						randomMutator = RandomGenerator.new() 	
						@logger.info("Mutating Chromosome: #{chromosomeID}")
						newChromosomeFilename = "tests" + File::SEPARATOR + "#{@nextGenerationNumber}.#{chromosomeID}." + fittestChromosome.split(".")[-1]
						FileUtils.cp(fittestChromosome, newChromosomeFilename) 
						File.open(newChromosomeFilename, "r+b")	do |chromosomeFD|
							mutationPoint = rand(chromosomeFD.size())
							chromosomeFD.seek(mutationPoint, IO::SEEK_SET)
							chromosomeFD.write(randomMutator.bytes(rand(10) + 1)) 
						end
						@temporaryMappings[chromosomeID] = newChromosomeFilename 
					end
				end
			end
		end
	end
end
