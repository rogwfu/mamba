module Mamba
	class Executor
		UTILIZATION_THRESH = 5.0
		POLLING_TIMEOUT = 4
		UPPERBOUND = 12

		
		# Initialize the executor with the correct application, delivery type, and timeout
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
		def run(log, testCase)
			log.info("Running Test Case: #{testCase}")
			pid, actualRunTime = @exeLambdas["run"].call(log, testCase)
		end

		def valrind_trace(log, testCase)
			log.info("Running Test Case: #{testCase}")
			pid, actualRunTime = @exeLambdas["valgrind"].call(testCase)
		end

		private

		def application_cleanup(pid)
			#
			# Cleanup the application
			#
			begin
				Process.kill("INT", pid)
				Process.wait(pid)
			rescue 
			ensure
				FileUtils.rm_f("app.pid." + pid.to_s())
			end
		end

		# Creates the lambda for the run function based on mamba's configuration
		def create_appscript_lambdas(appMonitor)
			#
			# Loop through the different tracer methods and create lambda
			#
			@supportedTracers.each_key do |tracerKey|
				@exeLambdas[tracerKey] = lambda do |log, newTestCase|
					@runningPid = Process.spawn("#{@supportedTracers[tracerKey]} " + @application, [:out, :err]=>["logs/application.log", File::CREAT|File::WRONLY|File::APPEND]) 
					FileUtils.touch("app.pid." + @runningPid.to_s())
					Process.spawn("opener.rb #{@runningPid} #{Dir.pwd() + File::SEPARATOR + newTestCase}")
					runtime = self.send(appMonitor.to_sym)
					application_cleanup(@runningPid)
					return [@runningPid, runtime]
				end
			end
		end

		def create_cli_lambdas(appMonitor, deliveryMethod)
			#
			# Loop through the different tracer methods and create lambda
			#
			@supportedTracers.each_key do |tracerKey|
				@exeLambdas[tracerKey] = lambda do |log, newTestCase|
					@runningPid = Process.spawn("#{@supportedTracers[tracerKey]} " + @application + " #{deliveryMethod}" + " #{newTestCase}", [:out, :err] => ["logs/application.log", File::CREAT|File::WRONLY|File::APPEND]) 
					FileUtils.touch("app.pid." + @runningPid.to_s())
					runtime = self.send(appMonitor.to_sym)
					application_cleanup(@runningPid)
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
