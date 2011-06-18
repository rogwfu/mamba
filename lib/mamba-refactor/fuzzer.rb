#
# Include Base Functionality Classes
#
require 'mamba-refactor/reporter'
require 'mamba-refactor/executor'
require 'mamba-refactor/storage'
require 'log4r'
require 'uuidtools'

# @author Roger Seagle, Jr. 
module Mamba
	class Fuzzer

		# Create a new instance of a fuzzer
		# @param [Hash] Contains global configuration of the mamba fuzzing framework
		def initialize(mambaConfig)
			@logger = init_logger("Fuzzer")
			@executor = Executor.new(mambaConfig[:app], mambaConfig[:executor], mambaConfig[:timeout], @logger)
			@uuid = mambaConfig[:uuid]

			#
			# Check for distributed fuzzer setup
			#
			if(self.class.to_s.start_with?("Mamba::Distributed")) then
				@reporter = Reporter.new(true)
				initialize_storage(mambaConfig)
			else
				@reporter = Reporter.new()
			end
			@reporter.watcher.start()
		end

		# Create a storage handler for mongodb filesystem
		# @param [Hash] Contains global configuration of the mamba fuzzing framework
		def initialize_storage(mambaConfig)
			@storage = Storage.new(mambaConfig[:server], mambaConfig[:port], mambaConfig[:uuid])
			@organizer = mambaConfig[:organizer]
		end

		# Create queues for messaging between nodes and coordinating fuzzing efforts
		# @param [AMQP::Client] Established connection to a rabbitmq server
		def initialize_queues(connection)
			#
			# Create new channel
			#
			@channel  = AMQP::Channel.new(connection)
			@channel2  = AMQP::Channel.new(connection)

			#
			# Create a new fanout channel
			#
			@topic_exchange = @channel2.topic("#{@uuid}.topic")
			@direct_exchange = @channel.direct("")
			@channel.prefetch(1)

			#
			# Setup Direct Queues
			#
			@queueHash = Hash.new()
			["testcases"].each do |queueName|
				@queue    = @channel.queue("#{@uuid}.testcases", :auto_delete => true)
				@queue.bind(@direct_exchange).subscribe(:ack => true, &method(queueName.to_sym()))
			end

			#
			# Setup Topic Queues
			#
			["commands", "crashes", "remoteLogging", "results"].each do |channelName|
				@queueHash[channelName] = @channel2.queue(UUIDTools::UUID.timestamp_create.to_s() + ".#{channelName}", :auto_delete => true)
				@queueHash[channelName].bind(@topic_exchange, :key => channelName).subscribe(&method(channelName.to_sym()))
			end

			#
			# Setup Distributed Crash Notification
			#
			@reporter.topic_exchange = @topic_exchange
		end
		
		# Pass through to the reporter, need to fix this
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (Crash file information)
		def crashes(header, payload)
			@logger.info("Got notification of a crash: #{payload}")
			@reporter.remote_notification(header, payload)
		end

		# Handler for remote commands sent via rabbitmq (used for shutdown)
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (the command)
		def commands(header, payload)
			case payload
			when /^shutdown$/
				EventMachine.stop_event_loop()
			else
				@logger.warn("Unrecognized remote command: #{payload}")
			end
		end

		# Handler for any remote logging events sent via rabbitmq (used for shutdown)
		# @param [AMQP::Protocol::Header] Header of an amqp message
		# @param [String] Payload of an amqp message (the message to log)
		def remoteLogging(header, payload)
			@logger.info("Cluster Message: #{payload}")
		end

		# Report the status of the fuzzer run (Start Time, Elapsed Time, Number of Test Cases, Number of Crashes, and Crashes themselves)
		def report()
			@logger.info("==========================================================")
			@logger.info("                       STATUS")
			@logger.info("==========================================================")
			@reporter.print_report(@logger)
			@logger.info("==========================================================")
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
			fuzzerType.gsub!(/^.+Mamba::(\w+):.+/, '\1')
			fuzzerConfig = YAML.load_file("configs/#{fuzzerType}.yml")
			return(fuzzerConfig)
		end

		# Print the configuration to the log file for historical purposes
		# @param [Hash] Fuzzer specific configuration hash
		def dump_config(fuzzerConfig)
            @logger.info("=================================================")
            @logger.info("\tAlgorithm Configuration")
            @logger.info("=================================================")
			fuzzerConfig.each_key do |key|
				@logger.info("#{key}: \t#{fuzzerConfig[key]}")
			end
            @logger.info("=================================================")
		end
	end
end
