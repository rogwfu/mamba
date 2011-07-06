module Mamba
	class DistributedSimpleGeneticAlgorithm < SimpleGeneticAlgorithm 

		# Function to run the fuzzing 
		def fuzz()
			AMQP.start(:host => "fuzz.io") do |connection|
				initialize_queues(connection)

				if(@organizer) then
					seed do |newTestCaseFilename, testCaseNumber|
						@storage.dbHandle.put(File.open(newTestCaseFilename), :_id => "0:#{testCaseNumber}", :filename => newTestCaseFilename)
						@direct_exchange.publish(testCaseNumber.to_s(), :routing_key => @queue.name)
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
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (test case to run)
		def testcases(header, testCaseNumber)

#			newTestCaseFilename = mangle_test_case(testCaseNumber)
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
#			header.ack()	

		end
	end
end
