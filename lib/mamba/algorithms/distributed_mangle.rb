module Mamba
	module Algorithms
		class DistributedMangle < Mangle 
			# Establishes the fuzzing algorithm for the distributed mangle fuzzer 
		  def fuzz()
			# Check about base test case
			if(!valid_base_test_case?) then
			  return()
			end

			# File is fine, open a descriptor for use during fuzzer
			@baseTestCaseFileDes = File.open(@mangleConfig['Basefile'], "rb")

			# Read section of data from base test case
			@sectionData = read_section() 

			# Initialize rabbitmq 
			init_amqp()

			# Wait for the fuzzing to finish
			@amqpThreads.each(&:join)
			@logger.info("Exiting normally")
		  end

		  # Publish all test cases to the queue to direct drones
		  def seed_test_cases()
			chan = init_amqp_channel()
			direct = init_amqp_exchange(chan, "testcases", "direct") 
			
			# Loop until a queue is listening
			while not @amqpConnection.queue_exists?("testcases")
			  sleep(0.2)
			end
			
			if(@organizer)
			  @mangleConfig['Number of Testcases'].times do |testCaseNumber|
				begin 
				  direct.publish(testCaseNumber.to_s(), :routing_key => "testcases")
				  direct.on_return do |basic_return, properties, payload|
					  puts "#{payload} was returned! reply_code = #{basic_return.reply_code}, reply_text = #{basic_return.reply_text}"
				  end
				  @logger.info("Publishing: #{testCaseNumber}, testcases")
				rescue Bunny::Exception => e
				  @logger.info("Exception during connection: #{e.class}: #{e.message}")
				end
			  end
			end

			# Clean up the channel
			chan.close()
		  end

		  # Function to handle results sent out by drones
		  def results()
			chan = init_amqp_channel()
			topic = init_amqp_exchange(chan, "#{@uuid}.topic", "topic") 

			timestamp = UUIDTools::UUID.timestamp_create.to_s()
			q = chan.queue("#{timestamp}.results").bind(topic, :routing_key => "results")
			q.subscribe(:block => true) do |delivery_info, header, payload|

			  @logger.info("Result received: #{payload}") 
			  @reporter.numCasesRun = @reporter.numCasesRun + 1

			  # Send the shutdown command 
			  if(@reporter.numCasesRun == @mangleConfig['Number of Testcases'] and @organizer) then
				@logger.info("Remove: pNeed to shut it all down")
				topic.publish("shutdown", :key => "commands")
			  end
			end
		  end

			# Function to run test cases received from the organizer
			def testcases()
			  chan = init_amqp_channel()
			  direct = init_amqp_exchange(chan, "testcases", "direct") 
			  q = chan.queue("testcases").bind(direct, :routing_key => "testcases")

			  # Connect to the topic exchange
			  topic = init_amqp_exchange(chan, "#{@uuid}.topic", "topic") 
			  
			  # Loop until a queue is listening (May have a race condition)
#			  while not @amqpConnection.queue_exists?("testcases")
#				sleep(0.2)
#			  end

			  q.subscribe(:block => true) do |delivery_info, header, testCaseNumber|
				@logger.info("Running testcase: #{testCaseNumber}")
				@reporter.currentTestCase = testCaseNumber
				newTestCaseFilename = mangle_test_case(testCaseNumber)
				@executor.run(@logger, newTestCaseFilename)

				# Store the file in the "cloud" :)
				@storage.dbHandle.put(File.open(newTestCaseFilename), :_id => "0:#{testCaseNumber}", :filename => newTestCaseFilename)

				# Post test case results
				topic.publish("Cluster Finished Test Case: #{testCaseNumber}", :key => "results")

				# Acknowledge the test case is done
				header.ack()	
  				# cancel the consumer to exit
				#   delivery_info.consumer.cancel
			  end
			end
		end
	end
end
