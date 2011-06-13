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
				# Testing sending messages
				#
				@channel.queue("testcases").publish("New Test Case")
				@exchange.publish("New Logging", :routing_key => "remoteLogging")
				@exchange.publish("New Crash", :routing_key => "crashes")
#				@exchange.publish("shutdown", :routing_key => "commands")
			end
		end

		def testcases(header, payload)
			@logger.info("Received a test case: #{payload}, routing key is #{header.routing_key}")
			# Acknowledge the test case is done
			header.ack()	
		end
	end
end
