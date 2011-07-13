module Mamba
	module Algorithms
		class ByteGeneticAlgorithm < SimpleGeneticAlgorithm 

			# @param [Array] An array of children file descriptors
			def mutate(children)
				@logger.info("Byte Genetic algorithm mutator")

				randomMutator = RandomGenerator.new() 	
				children.each do |child|
					tmpFile = File.new("tests" + File::SEPARATOR + "temp-test", 'wb+')
					child.rewind()
					childSize = child.size()
					0.upto(childSize) do
						if(Kernel.rand() < @simpleGAConfig['Mutation Rate']) then
							child.read(1)
							tmpFile.write(randomMutator.bytes(1))
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
