require 'zip/zip'
require 'mamba-refactor/algorithms/genetics/population'
require 'mamba-refactor/algorithms/genetics/chromosome'

module Mamba
	module Algorithms
		class SimpleGeneticAlgorithm <  Fuzzer
			DEFAULT_CROSSOVER_RATE = 0.20
			DEFAULT_MUTATION_RATE = 0.50
			DEFAULT_NUMBER_OF_GENERATIONS = 2
			DEFAULT_POPULATION_SIZE = 4
			DEFAULT_FITNESS_FUNCTION = "As"
			DEFAULT_INITIAL_POPULATION_FILE = "tests" + File::SEPARATOR + "testset.zip"
			MAX_FILE_SIZE = 524288000 # Maximum of 500MB 

			# Generate the YAML configuration file for Simple Genetic Algorithm Fuzzer
			def self.generate_config()
				simpleGAConfig = Hash.new()
				simpleGAConfig['Crossover Rate'] = 		DEFAULT_CROSSOVER_RATE 
				simpleGAConfig['Mutation Rate'] = 		DEFAULT_MUTATION_RATE
				simpleGAConfig['Maximum Generations'] = DEFAULT_NUMBER_OF_GENERATIONS 
				simpleGAConfig['Population Size'] = 	DEFAULT_POPULATION_SIZE 
				simpleGAConfig['Fitness Function'] = 	DEFAULT_FITNESS_FUNCTION	
				simpleGAConfig['Initial Population'] =  DEFAULT_INITIAL_POPULATION_FILE
				simpleGAConfig['Disassembly'] =		    ""	
				yield(simpleGAConfig) if block_given?()
				super(simpleGAConfig)
			end

			# Initialize SimpleGeneticAlgorithm fuzzer and the generic fuzzer class
			# @param [Hash] Hash of configuration parameters for Mamba
			def initialize(mambaConfig)
				super(mambaConfig)
				@simpleGAConfig = read_fuzzer_config(self.to_s())


				#
				# Print configuration to a log file
				#
				dump_config(@simpleGAConfig)

				# Error check disassembly information
				if(!File.exists?(@simpleGAConfig['Disassembly'])) then
					@logger.fatal("Disassembly file is not valid (#{@simpleGAConfig['Disassembly']})")
					exit(1)
				end

				# Error Check Population File
				if(!File.exists?(@simpleGAConfig['Initial Population'])) then
					@logger.fatal("Initial Population file is not valid (#{@simpleGAConfig['Initial Population']})")
					exit(1)
				end

				#
				# Initialize object members 
				#
				@population = Population.new()
				@testSetMappings = Hash.new()
				@temporaryMappings = Hash.new()
				@nextGenerationNumber = 0
				@objectDisassembly = Plympton::Disassembly.new(@simpleGAConfig['Disassembly'], @simpleGAConfig['Fitness Function'])
			end

			# Run the fuzzing job
			def fuzz()

				seed()

				@simpleGAConfig['Maximum Generations'].times do |generationNumber|
					@logger.info("Generation #{generationNumber} out of #{@simpleGAConfig['Maximum Generations']}")
					@nextGenerationNumber = generationNumber + 1
					@simpleGAConfig['Population Size'].times do |chromosomeID|
						traceFile = @testSetMappings[chromosomeID] + ".trace.xml"
						@executor.valgrind(@logger, @testSetMappings[chromosomeID], @objectDisassembly.attributes.name, traceFile)  
						@objectDisassembly.valgrind_coverage(traceFile)
						fitness = @objectDisassembly.evaluate()
						@logger.info("Member #{chromosomeID} Fitness: #{fitness.to_s('F')}")
						@population.push(Chromosome.new(chromosomeID, fitness))
						@reporter.numCasesRun = @reporter.numCasesRun + 1
					end
					statistics()

					# Only evolve a new generation if needed
					evolve() unless (@nextGenerationNumber) == @simpleGAConfig['Maximum Generations']
				end
			end

			private

			# Evolve a new generation and clear the current one
			def evolve()
				0.step(@simpleGAConfig['Population Size']-1, 2) do |childID|
					parents, children = open_parents_and_children(childID)

#					@logger.info("=================CHILDREN===============")
#					@logger.info("Evolving: #{@nextGenerationNumber}")
#					@logger.info("Parents: #{parents}")
#					@logger.info("Children: #{children}")
#					@logger.info("========================================")

					crossover(parents, children)
					mutate(children)
				end

				#
				# Choose the best chromosome to survive
				#
				elitism()

				cleanup()
			end

			# Reset variables and make deep copies where necessary
			def cleanup()
				@testSetMappings.clear() 
				@testSetMappings = Marshal.load(Marshal.dump(@temporaryMappings)) 
				@temporaryMappings.clear() 
				@population.clear()
			end

			# Function to compose new filenames for children of the next generation
			# @param [Fixnum] The current child number being generated
			# @param [String] The selection method for the parents
			# @returns [Array, Array] Opens File descriptors for parents and children  
			def open_parents_and_children(childID, selectionMethod="roulette")
				parents = Array.new()
				children = Array.new()

				2.times do
					parents << File.open(@testSetMappings[@population.send(selectionMethod.to_sym()).id], "rb") 
				end
#				@logger.info("In open function: " + parents.inspect())

				2.times do |iter| 
					id = childID + iter
					children << "tests" + File::SEPARATOR + "#{@nextGenerationNumber}."  + "#{id}." + parents[iter].path.split(".")[-1] 
					@temporaryMappings[childID + iter] = children[iter] 
				end
#				@logger.info("In open children: " + children.inspect())

				return [parents, children]
			end

			# Single point crossover of two parent chromosomes
			# @param [Array] Array of parent file descriptors 
			# @param [Array] Array of children filenames 
			def crossover(parents, children)
				if(rand() <= @simpleGAConfig['Crossover Rate']) then
					crossoverPoint = crossover_point(parents)
#					@logger.info("Crossover Point is: #{crossoverPoint}")
					crossover_files(parents, children, crossoverPoint)	
				else
					2.times do |iter|
#						@logger.info("Copying: #{parents[iter].path} to #{children[iter]}")
						FileUtils.cp(parents[iter].path, children[iter]) 
						children[iter] = File.open(children[iter], "r+b")
					end
				end

				# Cleanup filename arrays
				parents.each { |parent| parent.close()}
				parents.clear()
			end

			# Function to actually split the parent files and create children based on a crossover point
			# @param [Array] Array of parent file descriptors
			# @param [Array] Array of children filenames
			# @param [Fixnum] Byte offset to split the files and combine
			def crossover_files(parents, children, crossoverPoint)
				# Tricky code, works because ruby arrays have -1 indexing
				# So this ends up switching parents to create two different children
				# Mapping: child 0: 0 1 and child 1: 1 0
				2.times do |iter|
					children[iter] = File.open(children[iter], "w+b") 
					parents[iter-1].seek(crossoverPoint, IO::SEEK_SET)
					children[iter].write(parents[iter].read(crossoverPoint))
					children[iter].write(parents[iter-1].read())
					parents[iter-1].rewind()
				end	
			end

			# Select a crossover point based on file size and maximum allowed file size (in bytes)
			# @param [Array] Array of parent file descriptors
			# @returns [Fixnum] A byte offset for the crossover point
			def crossover_point(parents)

				# Determine the smaller of the two files (cache sizes)
				parentOne = parents[0].size()
				parentTwo = parents[1].size()
				randomBound = parentOne 
				if (parentTwo < parentOne) then
					randomBound = parentTwo
				end

				#
				# Randomly select crossover point (this may not work)
				#
				crossoverPoint = rand(randomBound)
				until (((crossoverPoint + (parentTwo - crossoverPoint)) < MAX_FILE_SIZE) and ((crossoverPoint + (parentTwo - crossoverPoint)) < MAX_FILE_SIZE)) 
					crossoverPoint = rand(randomBound)
				end

				return(crossoverPoint)
			end

			# Mutate a chromosome
			# @param [Array] An array of children file descriptors
			def mutate(children)
				children.each do |child|
					randomMutator = RandomGenerator.new() 	
					if(rand() < @simpleGAConfig['Mutation Rate']) then
						mutationPoint = rand(child.size())
						child.seek(mutationPoint, IO::SEEK_SET)
						child.write(randomMutator.bytes(rand(10) + 1)) # + 1 ensures at least one byte mutated
					end
					child.close()
				end
				children.clear()
			end

			# Copy the fittest chromosome of the current population to the next generation
			def elitism()
				@population.fittestChromosome
				replaceChromsomeID = rand(@simpleGAConfig['Population Size'])
#				@logger.info("Running elitism: #{@testSetMappings[@population.fittestChromosome.id]} to #{@temporaryMappings[replaceChromsomeID]}")
				FileUtils.cp(@testSetMappings[@population.fittestChromosome.id], @temporaryMappings[replaceChromsomeID]) 
			end

			# Seeds the initial population by unzipping the test cases
			def seed()
				chromosomeNumber = 0
				testSetMapping = File.open("tests" + File::SEPARATOR + "test_set_map.txt", "w+")
				Zip::ZipFile.open(@simpleGAConfig['Initial Population']) do |zipfile|
					zipfile.each do |entry|
						if(entry.directory?) then
							@logger.info("#{entry.name} is a directory!")
							testSetMapping.printf("%-50.50s: skipped\n", entry.name)
							next
						else
							testSetMapping.printf("%-50.50s: #{chromosomeNumber}\n", entry.name)

							#
							# Write the zipped file data
							#
							@testSetMappings[chromosomeNumber] = "tests" + File::SEPARATOR + "#{@nextGenerationNumber}." + "#{chromosomeNumber}#{File.extname(entry.name)}"
							File.open("#{@testSetMappings[chromosomeNumber]}", "w+") do |newTestCase|
								newTestCase.write(zipfile.read(entry.name))
							end
							yield(chromosomeNumber) if block_given?()
							chromosomeNumber += 1
						end
					end
				end
				testSetMapping.close()

				#
				# Error check number of chromosomes equal configuration
				#
				if(chromosomeNumber != @simpleGAConfig['Population Size']) then
					@logger.fatal("Valid Chromosomes in zip file (#{chromosomeNumber}) does not equal configured population size #{@simpleGAConfig['Population Size']}!")
					exit(1)
				end
			end

			# Calculate and log interesting population statistics
			def statistics()
				@logger.info("Total Generation Fitness: #{@population.fitness.to_s('F')}")
				@logger.info("Average Chromosome Fitness: #{(@population.fitness/@population.size()).to_s('F')}")
				@logger.info("Fittest Member: #{@population.max()}")
			end
		end
	end
end
