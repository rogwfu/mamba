require 'daemons'
require 'yaml'
require 'zip/zip'
require 'zip/zipfilesystem'

class Fuzz < Thor
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
			:log_dir   => "#{FileUtils.pwd()}/logs",
			:backtrace  => true
		}

		#
		# Read environments configuration
		#
		mambaConfiguration = read_config()

		#
		# Create a daemon process
		#
		Daemons.daemonize(daemonOptions)

		#
		# Hand over control to fuzzer
		#
		loop do
			sleep(1000)
		end
	end

	desc "stop", "Stop a Mamba Fuzzer"
	# Stop the Mamba Fuzzing Framework 
	def stop()
		say "Mamba Fuzzing Framework Stopping....", :blue
		pidFiles = Daemons::PidFile.find_files(FileUtils.pwd(), "MambaFuzzingFramework")
		if(pidFiles.length == 1) then
			Process.kill('SIGINT', File.open(pidFiles[0]).readline().chomp().to_i())
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
		mambaConfiguration = read_config()
		if(!configuration_sane?(mambaConfiguration)) then
			say "Error: Configuration contains illegal values", :red
			exit(1)
		end

		#
		# Remove any lingering package with the same name
		#
		packageFilename = mambaConfiguration[:uuid] + ".mamba"
		remove_old_package(packageFilename)
		swapped = swap_roles(mambaConfiguration)

		#
		# Create the Package File
		#
		Zip::ZipFile.open(packageFilename, Zip::ZipFile::CREATE) do |zipfile|
			entries = Dir.glob("configs/*.yml") + Dir.glob("disassemblies/*") + Dir.glob("models/*")
			entries.each do |entry|
				zipfile.add(entry, entry)
			end
		end

		#
		# Check for switching back to an organizer
		#
		swap_roles(mambaConfiguration, swapped)
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
				#
				if (entry.name =~ /^configs\/\w+\.yml/ or entry.name =~ /^disassemblies\/w+.fz/ or entry.name =~ /models\/w+.ml/) then
					#
					# Packaged file superseeds all other files
					#
					if(File.exists?(entry.name)) then
						FileUtils.rm(entry.name, :secure => true)
					end

					#
					# Extract the contents
					#
					zipfile.extract(entry, entry.name)
				else
					next
				end
			end
		end
	end

	no_tasks do
		# Reads the Mamba configuration file from the current environment
		# @return [Hash] configuration settings
		def read_config()
			config = YAML.load_file("configs/fuzzer.yml")
			return(config)
		end

		# Scrutinize the configuration to ensure validity
		# @param [Config] Hash of the configuration read in
		# @return [Boolean] Configuration sane or not
		def configuration_sane?(config)
			if(config[:uuid] !~ /^fz\w+$/) then
			   return(false)
			end
			return(true)
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
				FileUtils.rm_rf(Dir.glob("#{dir}/*"), :secure => true)
			end
		end

		# Swap roles from being organizer to package configuration files
		# @param [Config] Hash of the current configuration
		# @param [Swapped] Status of configuration, if it has been changed (default: false)
		# @return [Boolean] Status of if the configuration changed
		def swap_roles(config, swapped=false)

			if(config[:organizer] or swapped) then
				config[:organizer] = !config[:organizer]	
				mambaConfigFile = File.new("configs/fuzzer.yml", "w+")
				mambaConfigFile.write(YAML::dump(config))
				mambaConfigFile.close()
				return(true)
			end

			return(false)
		end
	end
end
