require 'mkmf'

module Mamba
	class Distrib < Thor
		@@version = "0.0.0"
		namespace :distrib

		desc "dstart", "Start the Mongodb database for distribution"
		# Starts the Mongodb database for distributed test case filesystem
		# @todo Redirect the output of find_executable to not show up on the screen 
		# @todo Better method for tracking mamba version information
		# @todo Switch on mongodb os information
		def dstart() 
			say "Mamba Fuzzing Framework: Starting Mongodb database", :blue
			mongoPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "mongodb", "mongodb-osx-x86_64-1.8.2-rc3", "bin"].join(File::SEPARATOR)
			mongod = find_executable("mongod", mongoPath + File::PATH_SEPARATOR + ENV['PATH'])
			storageDir = Dir.pwd + "/databases/"
			logFile = storageDir + "mongodb.log"
			system("#{mongod} --fork --logpath #{logFile} --logappend --dbpath #{storageDir}")
			FileUtils.rm("mkmf.log")
		end	

		desc "dstop", "Stop the Mongodb database for distribution"
		# Stops a running instance of the Mongodb database
		def dstop() 
			say "Mamba Fuzzing Framework: Stopping Mongodb database", :blue
			storageDir = Dir.pwd + "/databases/"
			lockFile = storageDir + "mongod.lock"
			lock = File.new(lockFile, "r")
			pid = lock.readline().to_i()
			lock.close()
			Process.kill("SIGTERM", pid)
		end

		desc "qstart", "Start the rabbitmq queueing system"
		# Start the rabbitmq queueing system for distributed jobs
		def qstart() 
			say "Mamba Fuzzing Framework: Starting rabbitmq queues", :blue
			rabbitmqPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "rabbitmq", "rabbitmq-server-2.3.1", "scripts"].join(File::SEPARATOR)
			rabbitmq = find_executable("rabbitmq-server", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			queueBaseDir = Dir.pwd + "/queues"
			queueLogDir = Dir.pwd + "/logs/rabbitmq"
			system("export RABBITMQ_MNESIA_BASE=#{queueBaseDir}; export RABBITMQ_LOG_BASE=#{queueLogDir}; #{rabbitmq} -detached")
			FileUtils.rm("mkmf.log") if File.exists?("mkmf.log")
		end	

		desc "qreset", "Resetting the rabbitmq queueing system"
		# Reset the rabbitmq queueing system for distributed jobs (empty the queues)
		def qreset() 
			say "Mamba Fuzzing Framework: Resetting rabbitmq queues", :blue
			rabbitmqPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "rabbitmq", "rabbitmq-server-2.3.1", "scripts"].join(File::SEPARATOR)
			rabbitmqctl = find_executable("rabbitmqctl", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			system("#{rabbitmqctl} force_reset")
			FileUtils.rm("mkmf.log")
		end

		desc "qstop", "Stop the rabbitmq queueing system"
		# Stop the rabbitmq queueing system for distributed jobs
		def qstop() 
			say "Mamba Fuzzing Framework: Stopping rabbitmq queues", :blue
			rabbitmqPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "rabbitmq", "rabbitmq-server-2.3.1", "scripts"].join(File::SEPARATOR)
			rabbitmqctl = find_executable("rabbitmqctl", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			system("#{rabbitmqctl} stop")
			FileUtils.rm("mkmf.log") if File.exists?("mkmf.log")
		end

		desc "start", "Start all distributed fuzzing components"
		def start() 
			say "Mamba Fuzzing Framework: Starting Distributed Environment", :blue
			%w(dstart qstart).each do |distTask| 
				invoke distTask.to_sym() 
			end
		end

		desc "stop", "Stop all distributed fuzzing components"
		def stop() 
			say "Mamba Fuzzing Framework: Stopping Distributed Environment", :blue
			%w(dstop qstop).each do |distTask| 
				invoke distTask.to_sym()
			end
		end
	end
end
