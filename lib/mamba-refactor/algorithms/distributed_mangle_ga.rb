module Mamba
	module Algorithms
		class DistributedMangleGeneticAlgorithm < DistributedSimpleGeneticAlgorithm
			include Mamba::Algorithms::Helpers::MangleMutation
		end
	end
end
