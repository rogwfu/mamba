module Mamba
	module Algorithms
		module Helpers
			module ByteMutation
				# Mutate a file by randoming selecting bytes through out the file with 
				# the probability for each byte being mutated being the Mutation Rate
				# @param [Array] An array of children file descriptors
				def mutate(children)
					@logger.info("In byte Mutation")
					randomMutator = RandomGenerator.new() 	
					children.each do |child|
						tmpFile = File.new("tests" + File::SEPARATOR + "temp-test", 'wb+')
						child.rewind()
						childSize = child.size()
						0.upto(childSize) do
							if(Kernel.rand() < @simpleGAConfig['Mutation Rate']) then
								child.read(1)
							#	tmpFile.write(randomMutator.bytes(1))
								@logger.info("Regular Child at: #{child.pos()}")
								@logger.info("Mutant Child at:  #{tmpFile.pos()}")
								mutByte = randomMutator.bytes(2)	
								@logger.info("Value should be: #{mutByte.inspect()}")
								tmpFile.write(mutByte)
							else
								tmpFile.write(child.read(1))
							end
						end
						child.close()
						tmpFile.close()
						FileUtils.mv(tmpFile.path(), child.path())
					end
					children.clear()
				end
			end
		end
	end
end
