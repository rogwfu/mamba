require 'log4r'

# @author Roger Seagle, Jr. 
module Mamba
	class Fuzzer

		# Create a new instance of a fuzzer
		def initialize()
			@logger = init_logger("Fuzzer")
			@reporter = Reporter.new()
			@reporter.watcher.start()
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
	end
end