module Mamba
	class Executor
		UTILIZATION_THRESH = 5.0
		POLLING_TIMEOUT = 4
		UPPERBOUND = 12

		@@valgrind = ENV['GEM_HOME'] + File::PATH_SEPARATOR + "mamba-refactor-0.0.0" +  File::PATH_SEPARATOR + "ext" +  File::PATH_SEPARATOR + "valgrind" +  File::PATH_SEPARATOR + "inst" +  File::PATH_SEPARATOR + "bin" +  File::PATH_SEPARATOR + "valgrind"

		# Initialize the executor with the correct application, delivery type, and timeout
		def initialize(app, deliveryMethod, timeout, log)
			@application = app
			@timeout = timeout

			# 
			# Create lambdas to eliminate multiple if checks
			#
			case deliveryMethod 
			when /^appscript$/ 
				#
				# Create the run 
				@runLambda = create_appscript_run_lambda() 
				@valgrindLambda = create_appscript_valgrind_lambda()
			when /^cli#.*/
				deliveryMethod.gsub!(/^cli#/, '')
				@runLambda = create_cli_run_lambda(deliveryMethod) 
#				@valgrindLambda = create_cli_valgrind_lambda(deliveryMethod) 
			else
				log.fatal("Unknown executor type: #{deliveryMethod}")
				exit(1) # fix this to throw some kind of error
			end
		end

		# Spawn the application under test feeding it a test case
		def run(log, testCase)
			log.info("Running Test Case: #{testCase}")
			pid, actualRunTime = @runLambda.call(testCase)
		end

		def valrind_trace(log, testCase)
			log.info("Running Test Case: #{testCase}")
			pid, actualRunTime = @valgrindLambda.call(testCase)
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
		def create_appscript_run_lambda()
			appscriptRunLambda = nil

			if(@timeout < 1) then
				appscriptRunLambda = lambda do |newTestCase|
					pid = Process.spawn(@application, [:out, :err]=>["logs/application.log", File::CREAT|File::WRONLY|File::APPEND]) 
					FileUtils.touch("app.pid." + pid.to_s())
					Process.spawn("opener.rb #{pid} #{Dir.pwd() + File::SEPARATOR + newTestCase}")
					runtime = cpu_scale(pid)
					application_cleanup(pid)
					return [pid, runtime]
				end
			else
				appscriptRunLambda = lambda do |newTestCase|
					pid = Process.spawn(@application, [:out, :err]=>["logs/application.log", File::CREAT|File::WRONLY|File::APPEND])
					FileUtils.touch("app.pid." + pid.to_s())
					Process.spawn("opener.rb #{pid} #{Dir.pwd() + File::SEPARATOR + newTestCase}")
					runtime = sleep(@timeout) 
					application_cleanup(pid)
					return [pid, runtime]
				end
			end
		end

		def create_appscript_valgrind_lambda()
			appscriptValgrindLambda = nil

			if(@timeout < 1) then
				appscriptValgrindLambda = lambda do
#					pid = Process.spawn(@application) # [:out, :err]=>["logs/application.log", "w"]
#					runtime = cpu_scale(pid)
#					application_cleanup(pid)
#					return[pid, runtime]
				end
			else
				appscriptValgrindLambda = lambda do
#					pid = Process.spawn(@application) # [:out, :err]=>["logs/application.log", "w"]
#					runtime = cpu_scale(pid)
#					application_cleanup(pid)
#					return[pid, runtime]
				end
			end

			return(appscriptValgrindLambda)
		end

		def create_cli_run_lambda(deliveryMethod)
			cliRunLambda = nil
			
			if(@timeout < 1) then
				cliRunLambda = lambda do |newTestCase|
					pid = Process.spawn(@application + " #{deliveryMethod}" + " #{newTestCase}", [:out, :err] => ["logs/application.log", File::CREAT|File::WRONLY|File::APPEND]) 
					runtime = cpu_scale(pid)
					application_cleanup(pid)
					return [pid, runtime]
				end
			else
				cliRunLambda = lambda do |newTestCase|
					pid = Process.spawn(@application + " #{deliveryMethod}" + " #{newTestCase}", [:out, :err] => ["logs/application.log", File::CREAT|File::WRONLY|File::APPEND]) 
					runtime = sleep(@timeout) 
					application_cleanup(pid)
					return [pid, runtime]
				end
			end

			return(cliRunLambda)
		end

		# Monitor CPU to determine lull in processing
		# @param [String] The process id to monitor
		# @return [Fixnum] The observed application runtime
		def cpu_scale(pid)
			cpuUtil = 100.0
			pollingCheck = 0
			runtime = 0
			
			#
			# Poll for cpu utilization to fall below a threshold
			#
			while (cpuUtil > Mamba::Executor::UTILIZATION_THRESH and pollingCheck < Mamba::Executor::UPPERBOUND) do
				sleep(Mamba::Executor::POLLING_TIMEOUT)
				runtime = runtime + Mamba::Executor::POLLING_TIMEOUT 
				processInfo = `ps aux #{pid} | tail -1`
				cpuUtil = processInfo.split(' ')[2].to_f()
				pollingCheck = pollingCheck + 1
			end

			#
			# Return the amount of time run
			#
			return(runtime)
		end
	end
end
