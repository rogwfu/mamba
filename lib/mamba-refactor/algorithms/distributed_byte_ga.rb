module Mamba
	module Algorithms
		class DistributedByteGeneticAlgorithm < DistributedSimpleGeneticAlgorithm
			include Mamba::Algorithms::Helpers::ByteMutation
		end
	end
end
