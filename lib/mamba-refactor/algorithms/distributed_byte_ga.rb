module Mamba
	module Algorithms
		class DistributedByteGeneticAlgorithm < DistributedSimpleGeneticAlgorithm
			include Mamba::Algorithms::ByteMutation
		end
	end
end
