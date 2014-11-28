require 'posix/spawn'
require 'process_exists'

module Mamba
  class Executor
	UTILIZATION_THRESH = 5.0
	POLLING_TIMEOUT = 4
	UPPERBOUND = 12

	# Hash For supported executors
	@@supportedTracers = 
	{
	  "run"  => "",  # Hack for now to simplify code (User must put %s in run string to signify where to put the test case)
	  "lldb" => "python #{ENV['HOME']}" + File::SEPARATOR + ".mamba" + File::SEPARATOR + "lldb-func-tracer.py -p fuzzpipe -s %s -x %s -- " 
	}

	  # Dynamically define cli executors
	  def self.define_cli_executors(appMonitor, deliveryMethod, application)
		@@supportedTracers.each do |tracer, options|
		  # @param [Logger] Instance of a log4r logger
		  # @param [String] Filename of test case to run
		  # @param [String] Full path to the object being traced for valgrind emulation
		  # @param [String] Filename to log trace information for valgrind emulation
		  # @returns [String] The amount of time the test case ran  
		  define_method(tracer.to_sym()) do |log, newTestCase, timeout= 0, objectName="", traceFile=""|
			log.info("Running Test Case: #{newTestCase}")
		  	#runner = "#{@@supportedTracers[tracer]} #{application} #{deliveryMethod} #{newTestCase}" % [objectName, traceFile]
			runner = ""
			case tracer
			when "run"
		  		runner = "#{@@supportedTracers[tracer]} #{application} #{deliveryMethod}" % [newTestCase]
			when "lldb"
			  if deliveryMethod.include?("%s") then
				runner = "#{@@supportedTracers[tracer]} #{application} #{deliveryMethod}" % [objectName, traceFile, newTestCase]
			  else
				runner = "#{@@supportedTracers[tracer]} #{application} #{deliveryMethod} #{newTestCase}" % [objectName, traceFile]
			  end
			else
			  log.info("Unsupported Tracer!")
			  exit(1)
			end
		  	log.info("Runner was: #{runner}")
		  	args = runner.split(' ')

		  	# Spwan the fuzzing process
		  	@runningPid  = POSIX::Spawn::spawn(*args, :out => ["logs/application-out.log", File::CREAT|File::WRONLY|File::APPEND], 
								  :err => ["logs/application-err.log", File::CREAT|File::WRONLY|File::APPEND])
		  	File.new("app.pid." + @runningPid.to_s(), "w+").close()
			# Setup a named pipe to retreive the UUT pid
			pidPipe = File.open("fuzzpipe", 'r')

			# Wait for the tracer to return a pid
			continue = true
			while continue
			  appPid = pidPipe.gets()
			  if appPid
				continue = false
			  end
			end
			appPid =~ /(\d+)/
		  	runtime = self.send(appMonitor.to_sym)
			pidPipe.close()	
		  	application_cleanup($1.to_i())
			
			# Ensure a trace file exists when necessary (FIXME)
			if tracer == "lldb" then
				if not File.exists?(traceFile) then
				  File.open(traceFile, 'w') do |fh|
					fh.write("<?xml version='1.0' encoding='ASCII'?><fuzz.io></fuzz.io>")	
				  end
				end
			end
		  	return(runtime.to_s())
		  end
		end
	  end

	  # Initialize the executor with the correct application, delivery type, and timeout
	  # @param [String] The application under test (must be full path)
	  # @param [String] How to delivery the test cases (currently: appscript or cli)
	  # @param [Integer] Amount of time to run the program under test per test case
	  # @param [Logger] Instance of a log4r logger
	  # @param [Hash] Configuration Hash of a specific fuzzer 
	  def initialize(app, deliveryMethod, timeout, log, fuzzerConfig)
		@application = app
		@timeout = timeout

		# Create the function symbol to kill an application under test
		if(@timeout < 1) then
		  appMonitor = "cpu_scale"
		else
		  appMonitor = "cpu_sleep"
		end

		# Create the execution lambdas 
		case deliveryMethod 
		when /^appscript$/ 
		  Mamba::Executor.define_appscript_executors(appMonitor, app)
		when /^cli#/
		  deliveryMethod.gsub!(/^cli/, '')
		  deliveryMethod.gsub!(/^#/, '')
		  Mamba::Executor.define_cli_executors(appMonitor, deliveryMethod, app)
		else
		  log.fatal("Unknown executor type: #{deliveryMethod}")
		  exit(1) # fix this to throw some kind of error
		end
	  end

	  private

	  # Kill the application under test
	  # @param [Integer] The process ID of the program under test
	  def application_cleanup(appPid)
		if Process.exists?(appPid)
		  Process.kill("SIGKILL", appPid)
		end

		begin
		  Timeout.timeout(2) do
			Process.wait2(@runningPid)
		  end
		rescue Timeout::Error
		  Process.kill("SIGKILL", @runningPid)
		end

		# Remove the process file
		FileUtils.rm_f("app.pid." + @runningPid.to_s())
	  end

	  # Monitor CPU to determine lull in processing
	  # @param [String] The process id to monitor
	  # @return [Fixnum] The observed application runtime
	  def cpu_scale()
		cpuUtil = 100.0
		pollingCheck = 0
		runtime = 0

		# Poll for cpu utilization to fall below a threshold
		while (cpuUtil > Mamba::Executor::UTILIZATION_THRESH and pollingCheck < Mamba::Executor::UPPERBOUND) do
		  sleep(Mamba::Executor::POLLING_TIMEOUT)
		  runtime = runtime + Mamba::Executor::POLLING_TIMEOUT 
		  processInfo = `ps aux #{@runningPid} | tail -1`
		  cpuUtil = processInfo.split(' ')[2].to_f()
		  pollingCheck = pollingCheck + 1
		end

		# Return the amount of time run
		return(runtime)
	  end

	  # Basically an alias for Kernel.sleep to facilitate Executor class metaprogramming
	  def cpu_sleep()
		sleep(@timeout)
	  end
  end
end
