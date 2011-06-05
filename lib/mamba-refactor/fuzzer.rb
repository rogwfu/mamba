require 'log4r'
require 'benchmark'

module Mamba
	class Fuzzer
		attr_accessor :logger

		# Create a new instance of a fuzzer
		def initialize()
			puts "Created a new fuzzer"
			@logger = init_logger("Fuzzer")
			@logger.info("==========================================================")
		end

		private 

		# Initialize a logger                                                                                                                                                                  
		# @params [String] Type of fuzzer, used to name the log file
		# @return [Logger] A logger created from the log4r library
		def init_logger(type)                                                                                                                                                                    
			logfilename     = "logs/#{type}." + Time.now.strftime("%Y-%m-%d-%H-%M-%S") + ".log"                                                                                                  
			logger          = Log4r::Logger.new('MambaFuzzer_Logger')                                                                                                                            
			pattern         = Log4r::PatternFormatter.new(:pattern => "%d %l %m")                                                                                                                
			logger.outputters = Log4r::FileOutputter.new("mambafuzzerlogfile", :filename => logfilename, :formatter => pattern, :truncate => true)                                               
			logger.level = Log4r::ALL                                                                                                                                                            
			return(logger)                                                                                                                                                                       
		end    
	end
end
