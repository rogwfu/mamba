module Mamba
	module Algorithms
		class CHCGeneticAlgorithm < SimpleGeneticAlgorithm
			include Mamba::Algorithms::Helpers::CHC
#			"Incest Prevention"
#			Random selection
#			Half Uniform crossover - 50% of the bytes are switched at random
#			Hamming distance does not exceed the distance threshold
		end
	end
end
