module Mamba
  module Algorithms
	class DistributedSimpleGeneticAlgorithm < SimpleGeneticAlgorithm 

	  # Function to run the fuzzing 
	  def fuzz()
		# Initialize rabbitmq 
		init_amqp()

		# Signal the testcase thread to seed
		if(@organizer) then
		  @@evolvedCV.signal()
		end

		# Wait for the fuzzing to finish
		@amqpThreads.each(&:join)
		@logger.info("Exiting normally")
	  end

	  # Function to handle results sent out by drones
	  def results()
		chan = init_amqp_channel()
		topic = init_amqp_exchange(chan, "#{@uuid}.topic", "topic") 

		timestamp = UUIDTools::UUID.timestamp_create.to_s()
		q = chan.queue("#{timestamp}.results").bind(topic, :routing_key => "results")
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (test case results)

		q.subscribe(:block => true) do |delivery_info, header, payload|
		  @logger.info("REMOVE: Result received: #{payload}") 
		  chromosomeInfo = payload.split(".")[1].split(":")[0]
		  fitness = payload.split(":")[1]
		  @logger.info("Chromosome[#{chromosomeInfo}]: #{fitness}")
		  @reporter.numCasesRun = @reporter.numCasesRun + 1

		  # Organizer must collect population information 
		  if(@organizer)
			@population.push(Chromosome.new(chromosomeInfo, BigDecimal.new(fitness)))

			# Check for condition to stop and condition to stop and evolve
			if(@population.size == @simpleGAConfig['Population Size']) then
			  @@evolvedMutex.synchronize do
				@@evolvedCV.wait(@@evolvedMutex)

				@logger.info(@population.inspect())
				statistics()

				@nextGenerationNumber = @nextGenerationNumber + 1
				unless (@nextGenerationNumber == @simpleGAConfig['Maximum Generations']) then
				  evolve() 
				else
				  topic.publish("shutdown", :key => "commands")
				end # end evolving
			  end # end mutex
			  # Signal to start seeding again
			  @@evolvedCV.signal()
			end # end population size check
		  end
		end
	  end

	  # Function to run test cases received from the organizer
	  # Note test case encoding is 1.0, where 1 is the generation, . a delimiter, and 0 population member number
	  def testcases()
		chan = init_amqp_channel()
		direct = init_amqp_exchange(chan, "testcases", "direct") 
		q = chan.queue("testcases").bind(direct, :routing_key => "testcases")

		# Connect to the topic exchange
		topic = init_amqp_exchange(chan, "#{@uuid}.topic", "topic") 

		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (test case to run)

		q.subscribe(:block => true) do |delivery_info, header, testCaseID|
		  remoteFD = @storage.dbHandle.get(testCaseID)
		  testCaseFilename = "tests#{File::SEPARATOR}#{remoteFD.filename}"
		  traceFile = testCaseFilename + ".trace.xml"

		  # Optimization (Organizer already has all the files)
		  if(!@organizer) then
			localFD = File.open(testCaseFilename, "w+b")
			localFD.write(remoteFD.read())
			localFD.close()
		  end

		  @reporter.currentTestCase = remoteFD.filename 
		  runtime = @executor.lldb(@logger, testCaseFilename, @timeout, @objectDisassembly.attributes.name, traceFile)  
		  @objectDisassembly.lldb_coverage(traceFile)
		  fitness = @objectDisassembly.evaluate(runtime)
		  @logger.info("Member #{testCaseID} Fitness: #{fitness.to_s('F')}")

		  # Store the results in the "cloud" :)
		  @storage.dbHandle.put(File.open(traceFile), :_id => "#{testCaseID}.trace", :filename => traceFile)
		  FileUtils.rm(traceFile)

		  # Cleanup remotes
		  if(!@organizer) then
			FileUtils.rm(testCaseFilename)
		  end

		  # Post test case results 0.1.2 (Generation.Chromosome:Fitness)
		  topic.publish(testCaseID + ":" + fitness.to_s('F'), :key => "results")

		  # Acknowledge the test case is done
		  header.ack()	
		end
	  end

	  private

	  # Publish all test cases to the queue to direct drones
	  # THIS FUNCTION SHOULD REPLACE seed_distributed!!!!!
	  # Function to handle seeding mongodb and rabbitmq for distributed genetic algorithm
	  # testCaseID Format: generationNumber.testcasenumber (e.g. 1.4 - means generation 1, chromosome 4)
	  # testCaseFilename format: generationNumber.testcasefilename (e.g. 2.4.pdf - means generation 2 chromomse 4 with filename 4.pdf)
	  def seed_test_cases()
		chan = init_amqp_channel()
		direct = init_amqp_exchange(chan, "testcases", "direct") 

		# Loop until a queue is listening
		while not @amqpConnection.queue_exists?("testcases")
		  sleep(0.2)
		end

		# Only the organizer can seed tests
		if(@organizer)
		  loop do 
			# Need a while loop for forever, plus figure out how to get the testcases
			# Determine how to seed the tests
			@@evolvedMutex.synchronize do
			  @@evolvedCV.wait(@@evolvedMutex)
			  @testSetMappings.each_key do |testCaseNumber|
				testCaseID = @nextGenerationNumber.to_s() + "." + testCaseNumber
				@logger.info("Test Case number is: #{testCaseNumber}")
				@logger.info("Class is: #{testCaseNumber.class}")
				@logger.info("Inspect: #{@testSetMappings.inspect()}")
				remoteTestCaseFilename = @testSetMappings[testCaseNumber].split(File::SEPARATOR)[-1]
				@storage.dbHandle.put(File.open(@testSetMappings[testCaseNumber]), :_id => testCaseID, :filename => remoteTestCaseFilename)
				begin 
				  direct.publish(testCaseID, :routing_key => "testcases")
				  direct.on_return do |basic_return, properties, payload|
					puts "#{payload} was returned! reply_code = #{basic_return.reply_code}, reply_text = #{basic_return.reply_text}"
				  end
				  @logger.info("Publishing: #{testCaseNumber}, testcases")
				rescue Bunny::Exception => e
				  @logger.info("Exception during connection: #{e.class}: #{e.message}")
				end
			  end # end looping over testset mappings
			end # end mute synchronize
			# Signal that seeding has finished
			@@evolvedCV.signal()
		  end # end infinite loop
		end # end if organizer
	  end

	  # Function to handle seeding mongodb and rabbitmq for distributed genetic algorithm
	  # testCaseID Format: generationNumber.testcasenumber (e.g. 1.4 - means generation 1, chromosome 4)
	  # testCaseFilename format: generationNumber.testcasefilename (e.g. 2.4.pdf - means generation 2 chromomse 4 with filename 4.pdf)
	  # @param [String] The test case number
	  def seed_distributed(testCaseNumber)
		testCaseID = @nextGenerationNumber.to_s() + "." + testCaseNumber
		@logger.info("Test Case number is: #{testCaseNumber}")
		@logger.info("Class is: #{testCaseNumber.class}")
		@logger.info("Inspect: #{@testSetMappings.inspect()}")
		remoteTestCaseFilename = @testSetMappings[testCaseNumber].split(File::SEPARATOR)[-1]
		@storage.dbHandle.put(File.open(@testSetMappings[testCaseNumber]), :_id => testCaseID, :filename => remoteTestCaseFilename)
		@direct_exchange.publish(testCaseID, :routing_key => @queue.name)
	  end

	  # Function to handle seeding mongodb and rabbitmq for distributed genetic algorithm
	  # testCaseID Format: generationNumber.testcasenumber (e.g. 1.4 - means generation 1, chromosome 4)
	  # testCaseFilename format: generationNumber.testcasefilename (e.g. 2.4.pdf - means generation 2 chromomse 4 with filename 4.pdf)
	  # @param [String] The test case number
	  def seed_distributed_temp(testCaseNumber)
		testCaseID = (@nextGenerationNumber-1).to_s() + "." + testCaseNumber
		remoteTestCaseFilename = @temporaryMappings[testCaseNumber].split(File::SEPARATOR)[-1]
		@storage.dbHandle.put(File.open(@temporaryMappings[testCaseNumber]), :_id => testCaseID, :filename => remoteTestCaseFilename)
		@direct_exchange.publish(testCaseID, :routing_key => @queue.name)
	  end

	end
  end
end
