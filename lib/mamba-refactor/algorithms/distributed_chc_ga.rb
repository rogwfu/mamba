module Mamba
	module Algorithms
		class DistributedCHCGeneticAlgorithm < DistributedSimpleGeneticAlgorithm
			include Mamba::Algorithms::Helpers::CHC
		end
	end
end
