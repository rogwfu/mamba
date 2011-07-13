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
					child.each_byte do |byte|
						@logger.info("Byte #{child.pos()}:#{byte}")
						if(Kernel.rand() < @simpleGAConfig['Mutation Rate']) then
							@logger.info("Mutate")
#							numWritten = child.write(randomMutator.bytes(1)) 
							tmpFile.write(randomMutator.bytes(1))
#							@logger.info("Wrote: #{numWritten} bytes")
						else
							tmpFile.print([byte].pack("c"))
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
