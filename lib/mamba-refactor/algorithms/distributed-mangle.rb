require "amqp"

module Mamba
	class DistributedMangle < Mangle 
		# Establishes the fuzzing algorithm for the distributed mangle fuzzer 
		def fuzz()
			#
			# Start Queueing and callback (EventMachine loop running here)
			#
			AMQP.start(:host => "fuzz.io") do |connection|
				initialize_queues(connection)
			#
			# Check about base test case
			#
			if(!valid_base_test_case?) then
				return()
			end

			# File is fine, open a descriptor for use during fuzzer
			@baseTestCaseFileDes = File.open(@mangleConfig['Basefile'], "rb")

			#
			# Read section of data from base test case
			#
			@sectionData = read_section() 

			seed_test_cases()
			
			# Be Kind, Cleanup
#			@baseTestCaseFileDes.close()
			end
		end

		# Publish all test cases to the queue to direct drones
		def seed_test_cases()
			if(@organizer) then
				@mangleConfig['Number of Testcases'].times do |testCaseNumber|
					@direct_exchange.publish(testCaseNumber.to_s(), :routing_key => @queue.name)
				end
			end
		end

		# Function to handle results sent out by drones
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (test case results)
		def results(header, payload)
			@logger.info(payload)
			@reporter.numCasesRun = @reporter.numCasesRun + 1
			
			#
			# Send the shutdown command 
			#
			if(@reporter.numCasesRun == @mangleConfig['Number of Testcases'] and @organizer) then
				@topic_exchange.publish("shutdown", :key => "commands")
			end
		end

		# Function to run test cases received from the organizer
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (test case to run)
		def testcases(header, testCaseNumber)
			@logger.info("Running testcase: #{testCaseNumber}")
			@reporter.currentTestCase = testCaseNumber
			newTestCaseFilename = mangle_test_case(testCaseNumber)
			@executor.run(@logger, newTestCaseFilename)

			# 
			# Store the file in the "cloud" :)
			#
			@storage.dbHandle.put(File.open(newTestCaseFilename), :_id => "0:#{testCaseNumber}", :filename => newTestCaseFilename)

			#
			# Post test case results
			#
			@topic_exchange.publish("Cluster Finished Test Case: #{testCaseNumber}", :key => "results")

			# Acknowledge the test case is done
			header.ack()	
		end
	end
end
