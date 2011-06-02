class Fuzz < Thor
	desc "start", "Start a Mamba Fuzzer"
	def start()
		puts "Starting Mamba"

		#
		# Daemonize the current process
		#
		daemon_options = {
			:app_name	=> "Mamba File Fuzzer",
			:multiple	=> false,
			:dir_mode	=> :normal,
			:dir		=> FileUtils.pwd(),
			:backtrace  => true
		}

		Daemons.run_proc("mambafuzzer", daemon_options) do
			sleep(5000)
		end
	end

	desc "stop", "Stop a Mamba Fuzzer"
	def stop()
		puts "Stopping Mamba"
		pid_files = Daemons::PidFile.find_files(FileUtils.pwd(), "mambafuzzer")
		Process.kill('SIGINT', File.open(pid_files[0]).readline().chomp().to_i())
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
