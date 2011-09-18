require 'bigdecimal'

module Mamba
	class Chromosome 
		attr_accessor	:id
		attr_accessor	:fitness
		attr_accessor	:intermediate

		include Comparable

		# Initialize a chromosome with an id and fitness
		# @param [Fixnum] The id number
		# @param [String] The fittness of the chromsome 
		# @param [Boolean] Intermediate child?
		def initialize(id=0,fitness="0.0", intermed=false)
			@id = id
			@intermediate = intermed

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

		# Test if the chromosome is an intermediate chromosome
		# @returns [Boolean] True if intermediate, False otherwise
		def intermediate?()
			return(@intermediate)
		end

		# Convenience method for printing a chromosome
		# @return [String] A string representation of the chromosome object
		def to_s()
			"#{self.class} (#{self.__id__}): ID: #{@id}, Fitness: #{@fitness.to_s('F')}, Intermediate: #{@intermediate}" 
		end
	end
end

