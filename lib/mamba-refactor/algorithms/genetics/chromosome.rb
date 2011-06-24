require 'bigdecimal'

module Mamba
	class Chromosome 
		attr_accessor	:id
		attr_accessor	:fitness

		include Comparable

		# Initialize a chromosome with an id and fitness
		def initialize(id=0,fitness="0.0")
			@id = id
			@fitness = BigDecimal(fitness)
		end

		# Comparison method for different chromosomes
		def <=>(other)
			@fitness <=> other.fitness
		end
	end
end

