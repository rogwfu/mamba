#
# Include Base Functionality Classes
#
require 'mamba/reporter'
require 'mamba/executor'
require 'mamba/storage'
require 'mamba/random-generator'
require 'log4r'
require 'uuidtools'
require 'bunny'

# @author Roger Seagle, Jr. 
module Mamba
	class Fuzzer

		# Class method to dump a fuzzer configuration
		# @param [Hash] A hash containing configuration parameters
		def self.generate_config(configuration)
			YAML::dump(configuration)
		end

		# Create a new instance of a fuzzer
		# @param [Hash] Contains global configuration of the mamba fuzzing framework
		# @param [Hash] Contains configuration of the inidivual fuzzer
		def initialize(mambaConfig, fuzzerConfig=nil)
			@logger = init_logger("Fuzzer")
			@executor = Executor.new(mambaConfig[:app], mambaConfig[:executor], mambaConfig[:timeout], @logger, fuzzerConfig)
			@uuid = mambaConfig[:uuid]
			@timeout = mambaConfig[:timeout]

			#
			# Check for distributed fuzzer setup
			#
			if(self.class.to_s.start_with?("Mamba::Algorithms::Distributed")) then
				@reporter = Reporter.new(true)
				@amqpServer = mambaConfig[:server]
				initialize_storage(mambaConfig)
			else
				@reporter = Reporter.new()
			end
			
			@logger.info("Starting the reporter watching thread")

			# Start the monitoring
			@reporter.watcher.start
		end

		# Create a storage handler for mongodb filesystem
		# @param [Hash] Contains global configuration of the mamba fuzzing framework
		def initialize_storage(mambaConfig)
			@storage = Storage.new(mambaConfig[:server], mambaConfig[:port], mambaConfig[:uuid])
			@organizer = mambaConfig[:organizer]
		end

		# Initialize a channel to use with rabbitmq
		# @return [type] A channel to rabbitmq
		def init_amqp_channel()
		  # Create a channel for amqp communication
		  begin 
			channel  = @amqpConnection.create_channel 
		  rescue Bunny::TCPConnectionFailed, Bunny::PossibleAuthenticationFailureError => e
			@logger.info("Exception during connection: #{e}")
		  end

		  # return 
		  return(channel)
		end

		# Initialize a new amqp exchange
		# @param [Bunny::Channel] An instance of a AMQP channel 
		# @param [String] The name of the exchange 
		# @param [String] The exchange type to create
		def init_amqp_exchange(chan, name, extype)
		  begin
			exchange = chan.exchange(name, {:type => extype})
		  rescue Bunny::TCPConnectionFailed, Bunny::PossibleAuthenticationFailureError => e
			@logger.info("Exception during connection: #{e}")
		  end

		  return(exchange)
		end

		# Create queues for messaging between nodes and coordinating fuzzing efforts
		# @return [Array] Array of threads associated to AMQP queues 
		def init_amqp()

		  @amqpThreads = Array.new()

		  # Start Queueing and callback (EventMachine loop running here)
		  begin 
			@amqpConnection = Bunny.new(:host => @amqpServer, :vhost => "/", :user => "newuser", :pass => "newuser")
			@amqpConnection.start
		  rescue Bunny::TCPConnectionFailed, Bunny::PossibleAuthenticationFailureError => e
			@logger.info("Exception during connection: #{e}")
		  end

		  # Setup Direct Queues (remoteLogging)
		  ["testcases", "seed_test_cases", "results", "commands", "crashes"].each do |queueName|
			@amqpThreads << Thread.new do
			  send(queueName.to_sym())
			end
		  end
		  
		end
		
		# Handler for remote commands sent via rabbitmq (used for shutdown)
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (the command)
		def commands()
		  chan = init_amqp_channel()
		  topic = init_amqp_exchange(chan, "#{@uuid}.topic", "topic") 

		  timestamp = UUIDTools::UUID.timestamp_create.to_s()
		  q = chan.queue("#{timestamp}.commands").bind(topic, :routing_key => "commands")
		  q.subscribe(:block => true) do |delivery_info, header, payload|
			case payload
			when /^shutdown$/
			  # Exit all of the other Threads
			  @amqpThreads.each do |thread|
				thread.exit unless thread == Thread.current
			  end

			  # Exit the current thread
			  Thread.current.exit()
			else
			  @logger.warn("Unrecognized remote command: #{payload}")
			end
		  end
		end

		# Pass through to the reporter, need to fix this
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (Crash file information)
		def crashes()
		  chan = init_amqp_channel()
		  topic = init_amqp_exchange(chan, "#{@uuid}.topic", "topic") 

		  timestamp = UUIDTools::UUID.timestamp_create.to_s()
		  q = chan.queue("#{timestamp}.crashes").bind(topic, :routing_key => "crashes")
		  q.subscribe(:block => true) do |delivery_info, header, payload|

			@logger.info("Got notification of a crash: #{payload}")
			#@reporter.remote_notification(header, payload)
		  end
		end
		
		# Handler for any remote logging events sent via rabbitmq (used for shutdown)
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (the message to log)
		def remoteLogging()
		  chan = init_amqp_channel()
		  topic = init_amqp_exchange(chan, "#{@uuid}.topic", "topic") 

		  timestamp = UUIDTools::UUID.timestamp_create.to_s()
		  q = chan.queue("#{timestamp}.remoteLogging").bind(topic, :routing_key => "log")
		  q.subscribe(:block => true) do |delivery_info, header, payload|
			@logger.info("Cluster Message: #{payload}")
		  end

		end

		# Report the status of the fuzzer run (Start Time, Elapsed Time, Number of Test Cases, Number of Crashes, and Crashes themselves)
		def report()
			@reporter.print_report(@logger)
		end

		private 

		# Initialize a logger
		# @param [Type] Type of fuzzer, used to name the log file
		# @return [Logger] A logger created from the log4r library
		def init_logger(type) 
			logfilename			= "logs/#{type}." + Time.now.strftime("%Y-%m-%d-%H-%M-%S") + ".log"
			logger				= Log4r::Logger.new('MambaFuzzer_Logger')
			pattern				= Log4r::PatternFormatter.new(:pattern => "%d %l %m")
			logger.outputters	= Log4r::FileOutputter.new("mambafuzzerlogfile", :filename => logfilename, :formatter => pattern, :truncate => true)
			logger.level		= Log4r::ALL
			return(logger)
		end 

		# Read the YAML configuration file for the fuzzer
		# @param [FuzzerType] The class name of the fuzzer type configured in mamba.yml
		def read_fuzzer_config(fuzzerType)
			fuzzerType.gsub!(/^.+Mamba::Algorithms::(\w+):.+/, '\1')
			fuzzerConfig = YAML.load_file("configs/#{fuzzerType}.yml")
			return(fuzzerConfig)
		end

		# Print the configuration to the log file for historical purposes
		# @param [Hash] Fuzzer specific configuration hash
		def dump_config(fuzzerConfig)
            @logger.info("==========================================================")
            @logger.info("\t\tAlgorithm Configuration")
            @logger.info("==========================================================")
			fuzzerConfig.each_key do |key|
				@logger.info("#{key}: \t#{fuzzerConfig[key]}")
			end
            @logger.info("==========================================================")
		end
	end
end

	# Create a new fanout exchange 
#			topic = init_amqp_exchange(chan, "#{@uuid.topic}", "topic") 

#			begin
#			  @topic_exchange = @channel2.topic("#{@uuid}.topic", :auto_delete => true)
#			rescue Bunny::TCPConnectionFailed, Bunny::PossibleAuthenticationFailureError => e
#			  @logger.info("Exception during connection: #{e}")
#			end
#
#			@direct_exchange = @channel.direct("testcases")
#			@channel.prefetch(1)
#			@logger.info("REMOVE: Finished with the Exchanges")
#
#			# Setup Direct Queues
#			@queueHash = Hash.new()
#			["testcases"].each do |queueName|
#				@logger.info("REMOVE: Before queue")
#			end
#			@logger.info("REMOVE: Added testcase queue")
#
#			# Setup Topic Queues
#			timestamp = UUIDTools::UUID.timestamp_create.to_s()
#			["commands", "crashes", "remoteLogging", "results"].each do |channelName|
#				@logger.info("REMOVE: Before creating the new queue:" + timestamp + ".#{channelName}")
#				@queueHash[channelName] = @channel2.queue(timestamp + ".#{channelName}", :auto_delete => true)
#				@logger.info("REMOVE: After creating the new queue #{channelName}")
#				amqpThreads << Thread.new do
#				  @queueHash[channelName].bind(@topic_exchange, :block => true, :key => channelName).subscribe(&method(channelName.to_sym()))
#				end
#			end
#			@logger.info("Topic queues added")
#
#			# Setup Distributed Crash Notification
#			@reporter.topic_exchange = @topic_exchange

