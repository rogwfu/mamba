require 'zip/zip'
require 'mamba-refactor/algorithms/genetics/population'
require 'mamba-refactor/algorithms/genetics/chromosome'

module Mamba
	class SimpleGeneticAlgorithm <  Fuzzer
        DEFAULT_CROSSOVER_RATE = 0.20
        DEFAULT_MUTATION_RATE = 0.50
        DEFAULT_NUMBER_OF_GENERATIONS = 2
        DEFAULT_POPULATION_SIZE = 4
        DEFAULT_FITNESS_FUNCTION = "As"

		DEFAULT_INITIAL_POPULATION_FILE = "tests/testset.zip"
#        DEFAULT_IDA_DUMP = "disassemblies/"
#        DEFAULT_INITIAL_POPULATION = "tests/testset.zip"
#        MAX_FILE_SIZE = 2097152

		# Generate the YAML configuration file for Simple Genetic Algorithm Fuzzer
		def self.generate_config()
			simpleGAConfig = Hash.new()
			simpleGAConfig['Crossover Rate'] = 		DEFAULT_CROSSOVER_RATE 
			simpleGAConfig['Mutation Rate'] = 		DEFAULT_MUTATION_RATE
			simpleGAConfig['Maximum Generations'] = DEFAULT_NUMBER_OF_GENERATIONS 
			simpleGAConfig['Population Size'] = 	DEFAULT_POPULATION_SIZE 
			simpleGAConfig['Fitness Function'] = 	DEFAULT_FITNESS_FUNCTION	
			simpleGAConfig['Initial Population'] =  DEFAULT_INITIAL_POPULATION_FILE
			YAML::dump(simpleGAConfig)
		end

		# Initialize SimpleGeneticAlgorithm fuzzer and the generic fuzzer class
		def initialize(mambaConfig)
			super(mambaConfig)
			@simpleGAConfig = read_fuzzer_config(self.to_s())
			
			#
			# Print configuration to a log file
			#
			dump_config(@simpleGAConfig)

			#
			# Seed the initial population
			#
			@population = Population.new()
			seed()
		end

		# Run the fuzzing job
		def fuzz()
			@simpleGAConfig['Maximum Generations'].times do |generationNumber|
				@logger.debug("Evolving")
				@population.each do |chromosome|
					chromosome.fitness = BigDecimal(rand(25).to_s())
					@logger.debug(chromosome)
				end
				statistics()
				# Only evolve a new generation if needed
				evolve() unless generationNumber == @simpleGAConfig['Maximum Generations']
			end

		end

		private

		# Evolve a new generation
		def evolve()
			(@simpleGAConfig['Population Size']/2).times do 
				@logger.info("Child")
				crossover()
				mutate()
			end
		end

		# Crossover two chromosomes
		def crossover()
			@logger.info("Crossover")
		end

		# Mutate a chromosome
		def mutate()
			@logger.info("Mutate")
		end

		# Seeds the initial population by unzipping the test cases
		def seed()
			#
			# Make sure its a zip file
			#
			if (!File.directory?("tests/0")) then
				FileUtils.mkdir_p("tests/0")
			end
			
			chromosomeNumber = 0
			testSetMapping = File.open("tests/test_set_map.txt", "w+")
			Zip::ZipFile.open(@simpleGAConfig['Initial Population']) do |zipfile|
				zipfile.each do |entry|
					if(entry.directory?) then
						@logger.info("#{entry.name} is a directory!")
						testSetMapping.printf("%-50.50s: skipped\n", entry.name)
						next
					else
						newChromosome = Chromosome.new(chromosomeNumber)
						testSetMapping.printf("%-50.50s: #{chromosomeNumber}\n", entry.name)

						#
						# Write the zipped file data
						#
						File.open("tests/0/#{chromosomeNumber}#{File.extname(entry.name)}", "w+") do |newTestCase|
							newTestCase.write(zipfile.read(entry.name))
						end
						@population.push(newChromosome)
						chromosomeNumber += 1
					end
				end
			end
			testSetMapping.close()

			#
			# Error check number of chromosomes equal configuration
			#
			if(chromosomeNumber != @simpleGAConfig['Population Size']) then
				@logger.fatal("Valid Chromosomes in zip file (#{chromosomeNumber} does not equal configured population size #{@simpleGAConfig['Population Size']}!")
				exit(1)
			end
		end

		# Calculate and log interesting population statistics
		def statistics()
			populationFitness = @population.sum()
			@logger.info("Total Generation Fitness: #{populationFitness.to_s('F')}")
			@logger.info("Average Chromosome Fitness: #{(populationFitness/@population.size()).to_s('F')}")
			@logger.info("Fittest Member: #{@population.max()}")
		end
	end
end
