module Mamba
  module Algorithms
	class DistributedCHCGeneticAlgorithm < DistributedSimpleGeneticAlgorithm
	  include Mamba::Algorithms::Helpers::CHC

	  # Dynamically define the results method for handling results from distributed clients
	  # @param [Boolean] If this instance is an organizer or drone
	  def self.define_results_method(organizer)
		if(!organizer) then

		  # Handle results returned from distributed worker as an organizer
		  # @param []
		  # @param []
		  define_method(:results) do |header, payload|
			chromosomeInfo = payload.split(".")[1].split(":")[0]
			fitness = payload.split(":")[1]
			@logger.info("Chromosome[#{chromosomeInfo}]: #{fitness}")
			@reporter.numCasesRun = @reporter.numCasesRun + 1
		  end
		else
		  # Handle results returned from distributed worker as an organizer
		  # @param []
		  # @param []
		  define_method(:results) do |header, payload|
			chromosomeInfo = payload.split(".")[1].split(":")[0]
			fitness = payload.split(":")[1]
			@logger.info("Chromosome[#{chromosomeInfo}]: #{fitness}")
			@reporter.numCasesRun = @reporter.numCasesRun + 1

			# Check for an intermediate child
			if(chromosomeInfo.include?("c"))
			  @population.push(Chromosome.new(chromosomeInfo, BigDecimal.new(fitness), true))
			else
			  @population.push(Chromosome.new(chromosomeInfo, BigDecimal.new(fitness)))
			end

			# Check for condition to stop and condition to stop and evolve
			if(@population.size == @simpleGAConfig['Population Size']) then
			  #@logger.info(@population.inspect())
			  statistics()

			  @nextGenerationNumber = @nextGenerationNumber + 1
			  unless (@reporter.numCasesRun >= (@simpleGAConfig['Maximum Generations'] * @simpleGAConfig['Population Size'])) then
				case evolve() 
				when 0
				  # Reseed the intermediate population
				  @temporaryMappings.each do |key, value|
					#@logger.info("Key is: #{key}, Value is: #{value}")
					seed_distributed_temp(key)
				  end

				when 1
				  # Reseed the next population
				  @testSetMappings.each_key do |key|
					seed_distributed(key)
				  end
				else
				  @logger.info("Unexpected case condition")
				end
			  else
				@topic_exchange.publish("shutdown", :key => "commands")
			  end
			elsif(@population.size == (@simpleGAConfig['Population Size'] + @temporaryMappings.size)) then

			  # Cleanup the temporary mappings
			  @temporaryMappings.clear()

			  # Sort the combined array
			  @sorted_population = @population.sort()

			  spawn_new_generation()

			  # Hack but should work?
			  cleanup()
			  chc_check_stopping()

			  # Reseed the next population
			  @testSetMappings.each do |key, value|
				#@logger.info("Key is: #{key}, Value is: #{value}")
				seed_distributed(key)
			  end
			end # end if 
		  end # define_method
		end # else
	  end # function

	  # Initialize the distributed environment for CHC GA
	  def initialize(mambaConfig)
		# Dynamically write results function
		Mamba::Algorithms::DistributedCHCGeneticAlgorithm.define_results_method(mambaConfig[:organizer])	

		# Call the Simple GA intializer
		super(mambaConfig)
	  end

	end
  end
end
