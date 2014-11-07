# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'mkmf'
require 'socket'

module Mamba
	class Distrib < Thor
		@@version = "0.1.0"
		namespace :distrib

		desc "dstart", "Start the Mongodb database for distribution"
		# Starts the Mongodb database for distributed test case filesystem
		# @todo Better method for tracking mamba version information
		# @todo Switch on mongodb os information
		def dstart() 
			say "Mamba Fuzzing Framework: Starting Mongodb database", :blue
#			mongoPath = [ENV['GEM_HOME'], "gems", "mamba-" + @@version, "ext", "mongodb", "mongodb-osx-x86_64-1.8.2-rc3", "bin"].join(File::SEPARATOR)
#			mongod = find_executable0("mongod", mongoPath + File::PATH_SEPARATOR + ENV['PATH'])
			mongod = find_executable0("mongod", ENV['PATH'])
			storageDir = Dir.pwd + File::SEPARATOR + "databases" + File::SEPARATOR
			pidFile = storageDir + File::SEPARATOR + "mongod.pid"
			logFile = storageDir + "mongodb.log"
			system("#{mongod} --fork --logpath #{logFile} --logappend --dbpath #{storageDir} --pidfilepath #{pidFile}")
		end	

		desc "dstop", "Stop the Mongodb database for distribution"
		# Stops a running instance of the Mongodb database
		def dstop() 
			say "Mamba Fuzzing Framework: Stopping Mongodb database", :blue
			storageDir = Dir.pwd + File::SEPARATOR + "databases" + File::SEPARATOR
			pidFile = storageDir + File::SEPARATOR + "mongod.pid"
			if(File.exists?(pidFile)) then
				pfile = File.new(pidFile, "r")
				pid = pfile.readline().to_i()
				pfile.close()
				Process.kill("SIGTERM", pid)
			else
				say "Error: Mongodb Database not running", :red
			end
		end

		desc "qstart", "Start the rabbitmq queueing system"
		# Start the rabbitmq queueing system for distributed jobs
		def qstart() 
			say "Mamba Fuzzing Framework: Starting rabbitmq queues", :blue
			rabbitmqPath = [ENV['HOME'], ".mamba", "rabbitmq-server-3.4.1", "scripts"].join(File::SEPARATOR)
			rabbitmq = find_executable0("rabbitmq-server", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			queueBaseDir = Dir.pwd + File::SEPARATOR + "queues"
			queueLogDir = Dir.pwd + File::SEPARATOR + "logs" + File::SEPARATOR + "rabbitmq"
			hostname = Socket::gethostname.split('.')[0] 
			say "env RABBITMQ_NODENAME=fuzzer@#{hostname} RABBITMQ_MNESIA_BASE=#{queueBaseDir} RABBITMQ_LOG_BASE=#{queueLogDir} #{rabbitmq} -detached" 
			system("env RABBITMQ_NODENAME=fuzzer@#{hostname} RABBITMQ_MNESIA_BASE=#{queueBaseDir} RABBITMQ_LOG_BASE=#{queueLogDir} #{rabbitmq} -detached")
		end	

		desc "qreset", "Resetting the rabbitmq queueing system"
		# Reset the rabbitmq queueing system for distributed jobs (empty the queues)
		def qreset() 
			say "Mamba Fuzzing Framework: Resetting rabbitmq queues", :blue
			rabbitmqPath = [ENV['HOME'], ".mamba", "rabbitmq-server-3.4.1", "scripts"].join(File::SEPARATOR)
			rabbitmqctl = find_executable0("rabbitmqctl", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			hostname = Socket::gethostname.split('.')[0] 
			system("#{rabbitmqctl} -n fuzzer@#{hostname} force_reset")
		end

		desc "qstatus", "Query the rabbitmq queueing system"
		# Query the status of rabbitmq queueing system 
		def qstatus() 
			say "Mamba Fuzzing Framework: Getting the status of rabbitmq queues", :blue
			rabbitmqPath = [ENV['HOME'], ".mamba", "rabbitmq-server-3.4.1", "scripts"].join(File::SEPARATOR)
			rabbitmqctl = find_executable0("rabbitmqctl", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			hostname = Socket::gethostname.split('.')[0] 
			system("#{rabbitmqctl} -n fuzzer@#{hostname} status")
		end

		desc "qstop", "Stop the rabbitmq queueing system"
		# Stop the rabbitmq queueing system for distributed jobs
		def qstop() 
			say "Mamba Fuzzing Framework: Stopping rabbitmq queues", :blue
			rabbitmqPath = [ENV['HOME'], ".mamba", "rabbitmq-server-3.4.1", "scripts"].join(File::SEPARATOR)
			rabbitmqctl = find_executable0("rabbitmqctl", rabbitmqPath + File::PATH_SEPARATOR + ENV['PATH'])
			hostname = Socket::gethostname.split('.')[0] 
			system("#{rabbitmqctl} -n fuzzer@#{hostname} stop")
		end

		desc "start", "Start all distributed fuzzing components"
		# Start all components of the distributed fuzzing environment
		def start() 
			say "Mamba Fuzzing Framework: Starting Distributed Environment", :blue
			%w(dstart qstart).each do |distTask| 
				invoke distTask.to_sym() 
			end
		end

		desc "stop", "Stop all distributed fuzzing components"
		# Stop all components of the distributed fuzzing environment
		def stop() 
			say "Mamba Fuzzing Framework: Stopping Distributed Environment", :blue
			%w(dstop qstop).each do |distTask| 
				invoke distTask.to_sym()
			end
		end
	end
end
