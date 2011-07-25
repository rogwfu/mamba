module Mamba
	module Algorithms
		module Helpers
			module CHC
				# Metaprogramming for additional options to GA Configuration Hash
				def self.included(base)
					class << base
						def generate_config()
							self.superclass.generate_config do |gaConfig|
								# Delete unused rates from the genetic algorithm's configuration
								gaConfig.delete("Mutation Rate")
								gaConfig.delete("Crossover Rate")
							end
						end
					end
				end


				def evolve() 
					0.step(@simpleGAConfig['Population Size']-1, 2) do |childID|
						# Randomly select parents
						parents, children = open_parents_and_children(childID, "random")
						crossover(parents, children)
					end

					# Cleanup the mess from this population
					cleanup()
				end

				# Half Uniform crossover (HUX) with incest prevention
				# @param [Array] Array of parent file descriptors 
				# @param [Array] Array of children filenames 
				def crossover(parents, children)
					2.times do |iter|
						@logger.info("Copying: #{parents[iter].path} to #{children[iter]}")
						FileUtils.cp(parents[iter].path, children[iter]) 
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
