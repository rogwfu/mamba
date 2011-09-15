require 'rubygems'
require 'mamba-refactor'
require 'daemons'
require 'yaml'
require 'zip/zip'

class Fuzz < Thor
	namespace :fuzz

	desc "start", "Start a Mamba Fuzzer"
	# Start the Mamba Fuzzing Framework 
	def start()
		say "Mamba Fuzzing Framework Starting....", :blue

		#
		# Daemonize the current process
		#
		daemonOptions = {
			:app_name	=> "MambaFuzzingFramework",
			:multiple	=> false,
			:dir_mode	=> :normal,
			:dir		=> FileUtils.pwd(),
			:log_dir   => "#{FileUtils.pwd()}#{File::SEPARATOR}logs",
			:backtrace  => true
		}

		#
		# Read environments configuration
		#
		mambaConfig = read_config()
		validate_params(mambaConfig)
		pwd = Dir.pwd() 

		#
		# Create a daemon process
		#
		Daemons.daemonize(daemonOptions)
		Dir.chdir(pwd)

		#
		# Hand over control to fuzzer
		#
		fuzzer = Kernel.const_get("Mamba").const_get("Algorithms").const_get(mambaConfig[:type]).new(mambaConfig)
		fuzzer.fuzz()
		fuzzer.report()
	end

	desc "stop", "Stop a Mamba Fuzzer"
	# Stop the Mamba Fuzzing Framework 
	def stop()
		say "Mamba Fuzzing Framework Stopping....", :blue
		pidFiles = Daemons::PidFile.find_files(FileUtils.pwd(), "MambaFuzzingFramework")
		if(pidFiles.length == 1) then
			#
			# Kill the running framework/catch no such process (ERSCH)
			begin
				Process.kill('SIGINT', File.open(pidFiles[0]).readline().chomp().to_i())
			rescue 
				say "Error: Mamba Fuzzing Framework not running!", :red
			ensure
				#
				# Cleanup support applications
				#
				cleanup_running_environment()
			end
		else
			say "Error: Mamba Fuzzing Framework not running!", :red
		end
	end

	desc "package", "Package Fuzzer Configuration Files"
	def package()
		say "Mamba Fuzzing Framework Packaging Environment....", :blue
		say "Warning: Old package files will be erased!", :yellow

		#
		# Read the Mamba Configuration
		# 
		mambaConfig = read_config()
		validate_params(mambaConfig)

		#
		# Remove any lingering package with the same name
		#
		packageFilename = mambaConfig[:uuid] + ".mamba"
		remove_old_package(packageFilename)
		swapped = swap_roles(mambaConfig)

		#
		# Create the Package File
		#
		Zip::ZipFile.open(packageFilename, Zip::ZipFile::CREATE) do |zipfile|
			entries = Dir.glob("configs#{File::SEPARATOR}*.yml") + Dir.glob("disassemblies#{File::SEPARATOR}*") + Dir.glob("models#{File::SEPARATOR}*") 
			# Need to fix for certain distributed fuzzers (Mangle)
i			#+ Dir.glob("tests#{File::SEPARATOR}*")
			entries.each do |entry|
				say "Adding: #{entry}", :blue
				zipfile.add(entry, entry)
			end
		end

		#
		# Check for switching back to an organizer
		#
		swap_roles(mambaConfig, swapped)
	end

	desc "unpackage", "Unpackage Fuzzer Configuration Files"
	# Unpackage a mamba file to configure a fuzzing environment
	def unpackage(archive=nil)
		say "Mamba Fuzzing Framework Unpackaging Environment...", :blue
		say "Warning: Old configurations, databases, disassembles, logs, models, queues, and tests will be erased!", :yellow

		#
		# Error check no configuration file given
		#
		if(!archive) then
			say "Error: No package file provided!", :red
			exit(1)
		end

		#
		# Cleanup Fuzzer's Environment 
		#
		cleanup_old_environment()

		#
		# Unzip the archive
		# 
		Zip::ZipFile.open(archive) do |zipfile|
			zipfile.each do |entry|
				#
				# Sanity check the packaged filename (Whitelist)
				# I know the disassemblies has a directory traversal vuln in it
				if (entry.name =~ /^configs\/\w+\.yml/ or entry.name =~ /^disassemblies\/[\w+.]fz/ or entry.name =~ /models\/\w+\.ml/ or entry.name =~ /^tests\/\w+\.\w+/) then
					#
					# Extract the contents
					#
					say "Writing: #{entry.name}", :blue
					zipfile.extract(entry, entry.name)
				else
					next
				end
			end
		end
	end
	
	desc "report", "Print a report of current activity to the logfile"
	# Unpackage a mamba file to configure a fuzzing environment
	def report()
		say "Mamba Fuzzing Framework reporting to log file....", :blue
		pidFiles = Daemons::PidFile.find_files(FileUtils.pwd(), "MambaFuzzingFramework")
		if(pidFiles.length == 1) then
			# Send the reporting signal (SIGINFO) to the fuzzer 
			begin
				Process.kill('SIGINFO', File.open(pidFiles[0]).readline().chomp().to_i())
			rescue 
				say "Error: Mamba Fuzzing Framework not running!", :red
			end
		else
			say "Error: Mamba Fuzzing Framework not running!", :red
		end
	end

	no_tasks do
		# Reads the Mamba configuration file from the current environment
		# @return [Hash] configuration settings
		def read_config()
			config = YAML.load_file("configs#{File::SEPARATOR}Mamba.yml")
			return(config)
		end

		# Validates parameters given to the mamba command line tool for illegal values
		# @param [Hash] Mamba configuration
		def validate_params(mambaConfig)

			#
			# Ensure correct format of UUID
			#
			if(mambaConfig[:uuid] !~ /^fz\w+$/) then
				say "Error: Incorrect UUID format (#{mambaConfig[:uuid]})", :red
				exit(1)	
			end

			#
			# Validate the Executors
			#
			if(mambaConfig[:executor] != "appscript" and mambaConfig[:executor] !~ /^cli#/) then
				say "Error: Unsupported Executor (#{mambaConfig[:executor]})", :red
				exit(1)	
			end

			validate_algorithm_type(mambaConfig[:type])
		end

		# Ensure fuzzing algorithm is implemented with required inheritance and methods
		# @param [String] The algorithm for fuzzing
		def validate_algorithm_type(type)
			algorithmsConst = Kernel.const_get("Mamba").const_get("Algorithms")

			#
			# Validate if defined
			#
			if(!algorithmsConst.const_defined?(type)) then
				say "Error: Unsupported fuzzing algorithm (#{type})", :red
				exit(1)	
			end

			#
			# Validate methods
			#
			if(!algorithmsConst.const_get(type).respond_to?("generate_config")) then
				say "Error: Unsupported fuzzing algorithm (#{type}) - Missing generate_config() method", :red
				exit(1)
			end

			if(!algorithmsConst.const_get(type).method_defined?("fuzz")) then
				say "Error: Unsupported fuzzing algorithm (#{type}) - Missing fuzz() method", :red
				exit(1)
			end

			#
			# Validate algorithms inheritance
			#
			if(!algorithmsConst.const_get(type).ancestors.to_s().include?("Mamba::Fuzzer")) then
				say "Error: Unsupported fuzzing algorithm (#{type}) - Does not inherit from Mamba::Fuzzer", :red
				exit(1)
			end

		end

		# Removes old package files from the Mamba environment
		# @param [Packagefilname] The filename of the package to remove 
		def remove_old_package(packageFilename)
			if(File.exists?(packageFilename)) then
				FileUtils.rm(packageFilename)
			end
		end

		# Removes all configurations, databases, disassembles, logs, models, queues, and tests
		# Ensures a clean environment for starting a new fuzzer
		def cleanup_old_environment()
			%w(configs databases disassembles logs models queues tests).each do |dir|
				FileUtils.rm_rf(Dir.glob("#{dir}#{File::SEPARATOR}*"), :secure => true)
			end
		end

		# Swap roles from being organizer to package configuration files
		# @param [Config] Hash of the current configuration
		# @param [Swapped] Status of configuration, if it has been changed (default: false)
		# @return [Boolean] Status of if the configuration changed
		def swap_roles(config, swapped=false)

			if(config[:organizer] or swapped) then
				config[:organizer] = !config[:organizer]	
				mambaConfigFile = File.new("configs#{File::SEPARATOR}Mamba.yml", "w+")
				mambaConfigFile.write(YAML::dump(config))
				mambaConfigFile.close()
				return(true)
			end

			return(false)
		end

		# Kill all currently running support programs (application under test, worker threads)
		# All support processesdrop a file in the form app.pid.#, where # is the process id
		def cleanup_running_environment()
			pidFilesApps = Dir.glob("app.pid.*")
			pidFilesApps.each do |pid|
				begin
					Process.kill('INT', pid.split(".")[-1].to_i())
				rescue 
					say "Warning: Application with pid (#{pid.split(".")[-1]}) not running!", :yellow
				ensure
					FileUtils.rm_f(pid)
				end
			end
		end
	end
end
