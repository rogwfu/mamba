module Mamba
  module Algorithms
	module Helpers
	  module MangleMutation
		# Metaprogramming for additional options to GA Configuration Hash
		# @param [Symbol] The class name
		def self.included(base)
		  class << base
			def generate_config()
			  self.superclass.generate_config do |gaConfig|
				gaConfig['Default Offset'] = Mamba::Algorithms::Mangle::DEFAULT_OFFSET 
				gaConfig['Header Size'] = Mamba::Algorithms::Mangle::DEFAULT_HEADER_SIZE 
			  end
			end
		  end
		end

		# Mutate a file by running each through the mangle algorithm 
		# Probabiliy of selection is One spin per child 
		# @param [Array] An array of children file descriptors
		def mutate(children)
		  children.each do |child|
			# Error Check File to ensure mutation can occur
			if(rand() < @simpleGAConfig['Mutation Rate'] and
			   child.size > (@simpleGAConfig['Default Offset'] + @simpleGAConfig['Header Size'])) then
			  mangle_test_case(child)
			end
			child.close()
		  end
		  children.clear()
		end

		# Create a mangled test case using Mangle's algorithm
		# @param [IO] An open child file descriptor 
		def mangle_test_case(childFD)
		  # Calculate the number of bytes to mutate
		  count = rand(@simpleGAConfig['Header Size']/10).to_i()

		  # Mangle the section data
		  count.times do
			displacement = rand(@simpleGAConfig['Header Size'])
			byteValue = rand(256)

			if(rand(2) && byteValue  < 128) then
			  byteValue  = 0xff
			end

			# Overwrite the selected byte
			childFD.seek(@simpleGAConfig['Default Offset'] + displacement, IO::SEEK_SET) 
			childFD.putc(byteValue)
		  end
		end
	  end
	end
  end
end
