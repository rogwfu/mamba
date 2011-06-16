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
				initialize_queues()
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
			#@baseTestCaseFileDes.close()
				#
				# Testing sending messages
				#
			#	@channel.queue("#{@uuid}.testcases").publish("New Test Case")
			#	@exchange.publish("New Logging", :routing_key => "#{@uuid}.remoteLogging")
			#	@exchange.publish("New Crash", :routing_key => "#{@uuid}.crashes")
			#	@exchange.publish("shutdown", :routing_key => "#{@uuid}.commands")
			end
		end

		def seed_test_cases()
			if(@organizer) then
				@mangleConfig['Number of Testcases'].times do |testCaseNumber|
				#	@channel.queue("#{@uuid}.testcases").publish(testCaseNumber)
					AMQP::Exchange.default.publish(testCaseNumber, :routing_key => "#{@uuid}.testcases")
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

			# Acknowledge the test case is done
			header.ack()	
		end
	end
end
