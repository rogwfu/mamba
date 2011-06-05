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
			mongoPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "mongodb", "mongodb-osx-x86_64-1.6.5", "bin"].join(File::SEPARATOR)
			mongod = find_executable("mongod", mongoPath + File::PATH_SEPARATOR + ENV['PATH'])
			storageDir = Dir.pwd + "/databases/"
			logFile = storageDir + "mongodb.log"
			system("#{mongod} --fork --logpath #{logFile} --logappend --dbpath #{storageDir}")
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
			puts "Starting rabbitmq queueing system"
			rabbitmqPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "rabbitmq", "rabbitmq-server-2.3.1", "scripts"].join(File::SEPARATOR)
			rabbitmq = find_executable("rabbitmq-server", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			queueBaseDir = Dir.pwd + "/queues"
			queueLogDir = Dir.pwd + "/logs/rabbitmq"
			system("export RABBITMQ_MNESIA_BASE=#{queueBaseDir}; export RABBITMQ_LOG_BASE=#{queueLogDir}; #{rabbitmq} -detached")
		end	

		desc "qreset", "Resetting the rabbitmq queueing system"
		# Reset the rabbitmq queueing system for distributed jobs (empty the queues)
		def qreset() 
			rabbitmqPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "rabbitmq", "rabbitmq-server-2.3.1", "scripts"].join(File::SEPARATOR)
			rabbitmqctl = find_executable("rabbitmqctl", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			system("#{rabbitmqctl} force_reset")
		end

		desc "qstop", "Stop the rabbitmq queueing system"
		# Stop the rabbitmq queueing system for distributed jobs
		def qstop() 
			puts "Stopping the rabbitmq queueing system"
			rabbitmqPath = [ENV['GEM_HOME'], "gems", "mamba-refactor-" + @@version, "ext", "rabbitmq", "rabbitmq-server-2.3.1", "scripts"].join(File::SEPARATOR)
			rabbitmqctl = find_executable("rabbitmqctl", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			system("#{rabbitmqctl} stop")
		end

		desc "start", "Start all distributed fuzzing components"
		def start() 
			puts "Started the distributed environment"
			#		%w(queue_start database_start).each |distTask| do
			#			invoke :task
			#		end
		end

		desc "stop", "Stop all distributed fuzzing components"
		def stop() 
			puts "Stopped the distributed environment"
			#		%w(queue_stop, database_stop).each |distTask| do
			#			invoke :
			#		end
		end
	end
end
