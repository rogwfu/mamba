module Mamba
	module Algorithms
		module Helpers
			module MangleMutation
				include Mamba::Algorithms::Helpers::MangleMixin

				# Mutate a file by running each through the mangle algorithm 
				# Probabiliy of selection is: 
				# @param [Array] An array of children file descriptors
				def mutate(children)
					@logger.info("In Mangle Mutation Function")
					children.each do |child|


					end
					children.clear()
				end
			end
		end
	end
end
