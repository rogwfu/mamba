require 'zip/zip'

module Mamba
	class Population 
		include Enumerable 

		# Initialize the population by setting empty 
		def initialize()
			@chromosomes = Array.new()
			@fitness = 0.0
		end

		# Each method to satisfy Enumerable Module requirement
		def each(&block)
			# Call the block given with each member as an argument
			 @members.each do |member| 
				 block.call(member)
			end
		end

		# Add chromosomes to the population
		def push(*chromosomes)

		end

		# Remove chromosomes from the population
		def pop()

		end

		def seed!()

		end
	end
end
