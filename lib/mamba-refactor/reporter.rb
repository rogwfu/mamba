require 'directory_watcher'
require 'rbconfig'

module Mamba
	class Reporter
		attr_accessor    :numCasesRun
		attr_accessor    :currentTestCase
		attr_accessor    :watcher

		# Initialize Reporter variables and create directory watcher instance
		def initialize()
			@numCasesRun = 0
			@numCrashes = 0
			@currentTestCase = 0
			@startTime = Time.now()
			@crashes =  Array.new()
			@watcher = DirectoryWatcher.new(os_crash_dir(), :pre_load => true)
			@watcher.interval = 2.0
			@watcher.add_observer do |*args|
				args.each do |event|
					#
					# Check for an added file
					#
					if(event[:type] == :added) then
						@numCrashes = @numCrashes + 1
						crash = Hash.new()
						crash['CrashReport'] = event[:path]
						crash['ProbTestCase'] = @currentTestCase
						crash['CrashTime'] = Time.now()

						#
						# Consider Files within 20 seconds of crash
						#
						lowerBound = crash['CrashTime'] - 10
						upperBound = crash['CrashTime'] + 10

						#
						# Add it to the global crashes
						#
						@crashes << crash
					end
				end
			end
			return(self)
		end

		# Print information pertaining to run time, test cases run, and crashes
		# @param [Logger] A log4r instance to print logging information on runtime and crashes
		def print_report(logger)
			logger.info("Start Time:               #{@startTime.strftime("%B %d, %Y (%A)- %I:%M:%S %p")}")
			logger.info("Elapsed Runtime:          #{Time.now() - @startTime} secs")
			logger.info("Number of Test Cases Run: #{@numCasesRun} ")
			logger.info("Number of Crashes Found:  #{@numCrashes}")
			logger.info("Crashes:                  ")

			#
			# Format the crash string
			#
			@crashes.each do |crash|
				logger.info(crash['CrashReport'] + " : " + crash['CrashTime'].strftime("%B %d, %Y - %I:%M:%S %p") + " : " + crash['ProbTestCase'].to_s())
			end
		end

		private

		# Determines the appropriate crash directory for the operating system
		# @return [String] Directoy to watch for crash logs
		def os_crash_dir()
			case Config::CONFIG["host_os"]
			when /^darwin10\.\d+\.\d+$/
				return("/Users/#{ENV['USER']}/Library/Logs/DiagnosticReports")
			else
				raise "Error: Unsupported Operating System (#{Config::CONFIG["host_os"]})"
			end
		end
	end
end
