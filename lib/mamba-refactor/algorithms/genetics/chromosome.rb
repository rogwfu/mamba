module Mamba
	class Chromosome 
		attr_accessor	:id
		attr_accessor	:fitness

		# Initialize a chromosome with an id and fitness
		def initialize(id=0,fitness=0)
			@id = id
			@fitness = fitness
		end

	end
end

