module Mamba
	module Algorithms
		class DistributedCHCGeneticAlgorithm < DistributedSimpleGeneticAlgorithm
			include Mamba::Algorithms::Helpers::CHC

			# Function to handle CHC results and evolution
			#
			def results(header, payload)
				chromosomeInfo = payload.split(".")
				@logger.info("Chromosome[#{chromosomeInfo[1]}]: #{chromosomeInfo[2]}")
				@reporter.numCasesRun = @reporter.numCasesRun + 1
				
				if(@organizer)
					@population.push(Chromosome.new(chromosomeInfo[1].to_i(), chromosomeInfo[2]))
					# Check for condition to stop and condition to stop and evolve
					if(@population.size == @simpleGAConfig['Population Size']) then
						@logger.info(@population.inspect())
						statistics()

						@nextGenerationNumber = @nextGenerationNumber + 1
						unless (@nextGenerationNumber) == @simpleGAConfig['Maximum Generations'] then
							@topic_exchange.publish("shutdown", :key => "commands")
							evolve() 
						#	@testSetMappings.each_key do |key|
						#		seed_distributed(key)
						#	end
						else
							@topic_exchange.publish("shutdown", :key => "commands")
						end
					end
				end
			end

		end
	end
end
