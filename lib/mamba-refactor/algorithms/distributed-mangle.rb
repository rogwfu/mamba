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
				@channel.queue("#{@uuid}.testcases").publish("New Test Case")
				@exchange.publish("New Logging", :routing_key => "#{@uuid}.remoteLogging")
				@exchange.publish("New Crash", :routing_key => "#{@uuid}.crashes")
				@exchange.publish("shutdown", :routing_key => "#{@uuid}.commands")
			end
		end

		def testcases(header, payload)
			@logger.info("Received a test case: #{payload}, routing key is #{header.routing_key}")
			# Acknowledge the test case is done
			header.ack()	
		end
	end
end
