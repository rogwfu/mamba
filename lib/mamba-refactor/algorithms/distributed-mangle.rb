require "amqp"

module Mamba
	class DistributedMangle < Mangle 
		#
		# Overwrite the fuzz function
		#
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
			
			#
			# Testing it out
			#
#			if(@organizer) then
#				@channel_cmds.publish("Fanout Message")
#			end

			# Be Kind, Cleanup
#			@baseTestCaseFileDes.close()
			end
		end

		def seed_test_cases()
			if(@organizer) then
				@mangleConfig['Number of Testcases'].times do |testCaseNumber|
				#	@channel.queue("#{@uuid}.testcases").publish(testCaseNumber)
					@logger.info("Seeding test case: #{testCaseNumber}")
					#@direct_exchange.publish(testCaseNumber.to_s(), :routing_key => @queue.name, :app_id => "Hello world")
					@direct_exchange.publish(testCaseNumber.to_s(), :routing_key => @queue.name)
				end
			end
		end

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
			# Testing the logging
			#
			if(testCaseNumber.to_i() > 30) then
				@fanout_exchange.publish("Log from testcase number: #{testCaseNumber}")
			end

			# Acknowledge the test case is done
			header.ack()	
		end
	end
end
