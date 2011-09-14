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
						chromosomeInfo = payload.split(".")
						@logger.info("Chromosome[#{chromosomeInfo[1]}]: #{chromosomeInfo[2]}")
						@reporter.numCasesRun = @reporter.numCasesRun + 1
					end
				else
					# Handle results returned from distributed worker as an organizer
					# @param []
					# @param []
					define_method(:results) do |header, payload|
						chromosomeInfo = payload.split(".")
						@logger.info("Chromosome[#{chromosomeInfo[1]}]: #{chromosomeInfo[2]}")
						@reporter.numCasesRun = @reporter.numCasesRun + 1
						@population.push(Chromosome.new(chromosomeInfo[1].to_i(), BigDecimal.new(chromosomeInfo[2])))

						# Check for condition to stop and condition to stop and evolve
						if(@population.size == @simpleGAConfig['Population Size']) then
							@logger.info(@population.inspect())
							statistics()

							@nextGenerationNumber = @nextGenerationNumber + 1
							unless (@reporter.numCasesRun >= (@simpleGAConfig['Maximum Generations'] * @simpleGAConfig['Population Size'])) then
								@topic_exchange.publish("shutdown", :key => "commands")
						#		evolve() 

								# Reseed the next population
						#		@testSetMappings.each_key do |key|
						#			seed_distributed(key)
						#		end

							else
								@topic_exchange.publish("shutdown", :key => "commands")
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

			# Function to handle CHC results and evolution
#			def results(header, payload)
#				chromosomeInfo = payload.split(".")
#				@logger.info("Chromosome[#{chromosomeInfo[1]}]: #{chromosomeInfo[2]}")
#				@reporter.numCasesRun = @reporter.numCasesRun + 1
#				
#				# Check the role of this node
#				if(@organizer)
#					@population.push(Chromosome.new(chromosomeInfo[1].to_i(), BigeDecimal.new(chromosomeInfo[2])))
#
#					# Check to see if the current 
#					# Check for condition to stop and condition to stop and evolve
#					if(@population.size == @simpleGAConfig['Population Size']) then
#						@logger.info(@population.inspect())
#						statistics()
#
#						@nextGenerationNumber = @nextGenerationNumber + 1
#						unless (@reporter.numCasesRun >= (@simpleGAConfig['Maximum Generations'] * @simpleGAconfig['Population Size'])) then
#							@topic_exchange.publish("shutdown", :key => "commands")
#							evolve() 
#
#							# Reseed the next population
#							@testSetMappings.each_key do |key|
#								seed_distributed(key)
#							end
#
#						else
#							@topic_exchange.publish("shutdown", :key => "commands")
#						end
#					end
#				end
#			end

		end
	end
end
