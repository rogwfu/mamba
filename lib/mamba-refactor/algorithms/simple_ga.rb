module Mamba
	class SimpleGeneticAlgorithm <  Fuzzer
        DEFAULT_CROSSOVER_RATE = 0.20
        DEFAULT_MUTATION_RATE = 0.50
        DEFAULT_NUMBER_OF_GENERATIONS = 2
        DEFAULT_POPULATION_SIZE = 4
        DEFAULT_FITNESS_FUNCTION = "As"

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
		end

		# Run the fuzzing job
		def fuzz()

		end

	end
end
