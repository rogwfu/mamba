require 'bigdecimal'

module Mamba
	class Chromosome 
		attr_accessor	:id
		attr_accessor	:fitness

		include Comparable

		# Initialize a chromosome with an id and fitness
		def initialize(id=0,fitness="0.0")
			@id = id
			if(!fitness.kind_of?(BigDecimal)) then
				@fitness = BigDecimal(fitness)
			else
				@fitness = fitness
			end
		end

		# Comparison method for different chromosomes
		def <=>(other)
			@fitness <=> other.fitness
		end

		# Convenience method for printing a chromosome
		# @return [String] A string representation of the chromosome object
		def to_s()
			"#{self.class} (#{self.__id__}): ID: #{@id}, Fitness: #{@fitness.to_s('F')}" 
		end
	end
end

