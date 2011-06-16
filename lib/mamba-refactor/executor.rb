module Mamba
	class Executor
		UTILIZATION_THRESH = 5.0
		POLLING_TIMEOUT = 4
		UPPERBOUND = 12

		# Initialize the executor with the correct application, delivery type, and timeout
		# @param [String] The application under test (must be full path)
		# @param [String] How to delivery the test cases (currently: appscript or cli)
		# @param [Integer] Amount of time to run the program under test per test case
		# @param [Logger] Instance of a log4r logger
		def initialize(app, deliveryMethod, timeout, log)
			@application = app
			@timeout = timeout
			@exeLambdas = Hash.new()
	
			#
			# Hash For supported executors
			#
			@supportedTracers = 
				{
				"run"  => "",
				"valgrind" => ENV['GEM_HOME'] + File::PATH_SEPARATOR + "mamba-refactor-0.0.0" +  File::PATH_SEPARATOR + "ext" +  File::PATH_SEPARATOR + "valgrind" +  File::PATH_SEPARATOR + "inst" +  File::PATH_SEPARATOR + "bin" +  File::PATH_SEPARATOR + "valgrind"
			}
		
			#
			# Create the function symbol to kill an application under test
			#
			if(@timeout < 1) then
				appMonitor = "cpu_scale"
			else
				appMonitor = "cpu_sleep"
			end

			#
			# 
			# Create the execution lambdas 
			#
			case deliveryMethod 
			when /^appscript$/ 
				create_appscript_lambdas(appMonitor) 
			when /^cli#/
				deliveryMethod.gsub!(/^cli#/, '')
				create_cli_lambdas(appMonitor, deliveryMethod) 
			else
				log.fatal("Unknown executor type: #{deliveryMethod}")
				exit(1) # fix this to throw some kind of error
			end
		end

		# Spawn the application under test feeding it a test case
		# @param [Logger] Instance of log4r logger
		# @param [String] Location of the test case to run
		def run(log, testCase)
			log.info("Running Test Case: #{testCase}")
			pid, actualRunTime = @exeLambdas["run"].call(log, testCase)
		end

		# Spawn the application under test with valgrind 
		# @param [Logger] Instance of log4r logger
		# @param [String] Location of the test case to run
		def valrind_trace(log, testCase)
			log.info("Running Test Case: #{testCase}")
			pid, actualRunTime = @exeLambdas["valgrind"].call(testCase)
		end

		private

		# Kill the application under test
		def application_cleanup()
			#
			# Cleanup the application
			#
			begin
				Process.kill("INT", @runningPid)
				Process.wait(@runningPid)
			rescue 
			ensure
				# Remove the process file
				FileUtils.rm_f("app.pid." + @runningPid.to_s())
			end
		end

		# Creates the appscript lambdas based on mamba's configuration
		# @param [String] The type of application monitor (either cpu_scale or cpu_sleep)
		def create_appscript_lambdas(appMonitor)
			#
			# Loop through the different tracer methods and create lambda
			#
			@supportedTracers.each_key do |tracerKey|
				@exeLambdas[tracerKey] = lambda do |log, newTestCase|
					@runningPid = Process.spawn("#{@supportedTracers[tracerKey]} " + @application, [:out, :err]=>["logs/application.log", File::CREAT|File::WRONLY|File::APPEND]) 
					FileUtils.touch("app.pid." + @runningPid.to_s())
					appscriptPid = Process.spawn("opener.rb #{@runningPid} #{Dir.pwd() + File::SEPARATOR + newTestCase}")
					runtime = self.send(appMonitor.to_sym)

					#
					# Try to kill the applescript process to eliminate zombies
					#
					begin
						Process.kill("INT", appscriptPid)
						Process.wait(appscriptPid)
					rescue
					end

					application_cleanup()
					return [@runningPid, runtime]
				end
			end
		end

		# Creates the cli lambdas based on mamba's configuration
		# @param [String] The type of application monitor (either cpu_scale or cpu_sleep)
		def create_cli_lambdas(appMonitor, deliveryMethod)
			#
			# Loop through the different tracer methods and create lambda
			#
			@supportedTracers.each_key do |tracerKey|
				@exeLambdas[tracerKey] = lambda do |log, newTestCase|
					@runningPid = Process.spawn("#{@supportedTracers[tracerKey]} " + @application + " #{deliveryMethod}" + " #{newTestCase}", [:out, :err] => ["logs/application.log", File::CREAT|File::WRONLY|File::APPEND]) 
					FileUtils.touch("app.pid." + @runningPid.to_s())
					runtime = self.send(appMonitor.to_sym)
					application_cleanup()
					return [@runningPid, runtime]
				end
			end
		end

		# Monitor CPU to determine lull in processing
		# @param [String] The process id to monitor
		# @return [Fixnum] The observed application runtime
		def cpu_scale()
			cpuUtil = 100.0
			pollingCheck = 0
			runtime = 0
			
			#
			# Poll for cpu utilization to fall below a threshold
			#
			while (cpuUtil > Mamba::Executor::UTILIZATION_THRESH and pollingCheck < Mamba::Executor::UPPERBOUND) do
				sleep(Mamba::Executor::POLLING_TIMEOUT)
				runtime = runtime + Mamba::Executor::POLLING_TIMEOUT 
				processInfo = `ps aux #{@runningPid} | tail -1`
				cpuUtil = processInfo.split(' ')[2].to_f()
				pollingCheck = pollingCheck + 1
			end

			#
			# Return the amount of time run
			#
			return(runtime)
		end

		# Basically an alias for Kernel.sleep to facilitate Executor class metaprogramming
		def cpu_sleep()
			sleep(@timeout)
		end
	end
end
