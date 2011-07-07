module Mamba
	class DistributedSimpleGeneticAlgorithm < SimpleGeneticAlgorithm 

		# Function to run the fuzzing 
		def fuzz()
			AMQP.start(:host => @amqpServer) do |connection|
				initialize_queues(connection)

				if(@organizer) then
					seed do |newTestCaseFilename, testCaseNumber|
						testCaseID = "0" + "." + testCaseNumber.to_s()
						remoteTestCaseFilename = "0." + newTestCaseFilename.split(File::SEPARATOR)[-1]
						@storage.dbHandle.put(File.open(newTestCaseFilename), :_id => testCaseID, :filename => remoteTestCaseFilename)
						@direct_exchange.publish(testCaseID, :routing_key => @queue.name)
					end
				end

			end
		end

		# Function to handle results sent out by drones
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (test case results)
		def results(header, payload)
			@logger.info(payload)
			@reporter.numCasesRun = @reporter.numCasesRun + 1
		end

		# Function to run test cases received from the organizer
		# Note test case encoding is 1.0, where 1 is the generation, . a delimiter, and 0 population member number
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (test case to run)
		def testcases(header, testCaseNumber)

			remoteFD = @storage.dbHandle.get(testCaseNumber)
			localFD = File.open("tests#{File::SEPARATOR}#{remoteFD.filename}", "w+b")
			localFD.write(remoteFD.read())
			localFD.close()
#			@executor.run(@logger, newTestCaseFilename)

			# 
			# Store the file in the "cloud" :)
			#
#			@storage.dbHandle.put(File.open(newTestCaseFilename), :_id => "0:#{testCaseNumber}", :filename => newTestCaseFilename)

			#
			# Post test case results
			#
#			@topic_exchange.publish("Cluster Finished Test Case: #{testCaseNumber}", :key => "results")

			# Acknowledge the test case is done
			header.ack()	
		end
	end
end
