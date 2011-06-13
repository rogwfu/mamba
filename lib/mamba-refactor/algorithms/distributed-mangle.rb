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
				#
				# Create new channel
				#
				channel  = AMQP::Channel.new()
				exchange = channel.topic("uuid", :auto_delete => true)

				#
				# Bind for test cases 
				#
				channel.prefetch(0)
				channel.queue("uuid.testcases").bind(channel.direct("uuid.testcase")).subscribe(:ack => true) do |header, payload|
					@logger.info("Received a test case: #{payload}, routing key is #{header.routing_key}")
					header.ack()
				end

				#
				# Bind for logging
				#
				channel.queue("uuid.logging").bind(exchange, :routing_key => 'uuid.logging.#').subscribe do |headers, payload|
					@logger.info("Received logging information: #{payload}, routing key is #{headers.routing_key}")
				end

				#
				# Bind for crashes 
				#
				channel.queue("uuid.crashes").bind(exchange, :routing_key => 'uuid.crashes.#').subscribe do |headers, payload|
					@logger.info("Got information about crashes: #{payload}, routing key is #{headers.routing_key}")
				end

				#
				# Bind for crashes 
				#
				channel.queue("uuid.commands").bind(exchange, :routing_key => 'uuid.commands.#').subscribe do |headers, payload|
					@logger.info("Shutting down: #{payload}, routing key is #{headers.routing_key}")
					EventMachine.stop_event_loop()
				end

				#
				# Testing sending messages
				#
				channel.queue("uuid.testcase").publish("New Test Case")
				exchange.publish("New Logging", :routing_key => "uuid.logging")
				exchange.publish("New Crash", :routing_key => "uuid.crashes")
				exchange.publish("Shutdown", :routing_key => "uuid.commands")
			end
		end
	end
end
