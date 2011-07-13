module Mamba
	module Algorithms
		class ByteGeneticAlgorithm < SimpleGeneticAlgorithm 

			# @param [Array] An array of children file descriptors
			def mutate(children)
				@logger.info("Byte Genetic algorithm mutator")

				randomMutator = RandomGenerator.new() 	
				children.each do |child|
					tmpFile = File.new("tests" + File::SEPARATOR + "temp-test", 'wb+')
					@logger.info("(Before rewind) Child: #{child.inspect()}, Position: #{child.pos()}")
					child.rewind()
					@logger.info("Child: #{child.inspect()}, Position: #{child.pos()}")
					childSize = child.size()
					0.upto(childSize) do
						if(Kernel.rand() < @simpleGAConfig['Mutation Rate']) then
							@logger.info("Mutating")
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
				@logger.info("Finished loop")
				children.clear()
			end
		end
	end
end
