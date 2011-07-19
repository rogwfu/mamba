module Mamba
	module Algorithms
		module Helpers
			module MangleMutation
				# Mutate a file by running each through the mangle algorithm 
				# Probabiliy of selection is: 
				# @param [Array] An array of children file descriptors
				def mutate(children)
					@logger.info("In Mangle Mutation Function")
					children.each do |child|
						# Error Check File to ensure mutation can occur
	                    if(rand() < @simpleGAConfig['Mutation Rate'] and
						   child.size > (@beginOffset + @hdrSize)) then
							mangle_test_case(child)
                    	end
					end
					children.clear()
				end

				# Create a mangled test case using mangle's algorithm
				# @param [IO] An open child file descriptor 
				def mangle_test_case(childFD)
					# Calculate the number of bytes to mutate
					count = rand(@mangleConfig['Header Size']/10).to_i()

					# Seek to the starting offset
					child.seek(@beginOffset, IO::SEEK_SET)

					# Mangle the section data
					count.times do
						displacement = rand(@mangleConfig['Header Size'])
						byteValue = rand() % 256

						if(rand() % 2 && byteValue  < 128) then
							byteValue  = 0xff
						end
						
						# Overwrite the selected byte
						child.seek(@beginOffset + displacement, IO::SEEK_SET) 
						child.write(byteValue, 1)
					end
				end
			end
		end
	end
end
