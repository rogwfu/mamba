require 'daemons'

class Fuzz < Thor
	desc "start", "Start a Mamba Fuzzer"
	# Start the Mamba Fuzzing Framework 
	def start()
		puts "Mamba Fuzzing Framework Starting...."

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
		puts "Mamba Fuzzing Framework Starting...."
		pidFiles = Daemons::PidFile.find_files(FileUtils.pwd(), "MambaFuzzingFramework")
		if(pidFiles.length == 1) then
			Process.kill('SIGINT', File.open(pidFiles[0]).readline().chomp().to_i())
		else
			puts "Error: Mamba Fuzzing Framework not running!!!"
		end
	end

	desc "package", "Package Fuzzer Configuration Files"
	def package()
		puts "Packaging Files"
	end

	desc "unpackage", "Unpackage Fuzzer Configuration Files"
	def unpackage()
		puts "Unpackaging Files"
	end
end
