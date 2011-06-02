class Distrib < Thor

	desc "dstart", "Start the Mongodb database for distribution"
    def dstart() 
        puts "Starting Mongodb database"
        mongod = File.dirname(__FILE__) + "/../../../ext/mongodb/mongodb-osx-x86_64-1.6.5/bin/mongod"
        storageDir = Dir.pwd + "/databases/"
        logFile = storageDir + "mongodb.log"
        system("#{mongod} --fork --logpath #{logFile} --logappend --dbpath #{storageDir}")
    end	

    desc "dstop", "Stop the Mongodb database for distribution"
    def dstop() 
        puts "Stopping Mongodb database"
        storageDir = Dir.pwd + "/databases/"
        lockFile = storageDir + "mongod.lock"
        lock = File.new(lockFile, "r")
        pid = lock.readline().to_i()
        lock.close()
        Process.kill("SIGTERM", pid)
    end

    desc "qstart", "Start the rabbitmq queueing system"
	def qstart() 
		puts "Starting rabbitmq queueing system"
		rabbitmq = File.dirname(__FILE__) + "/../../../ext/rabbitmq/rabbitmq-server-2.3.1/scripts/rabbitmq-server"
		queueBaseDir = Dir.pwd + "/queues"
		queueLogDir = Dir.pwd + "/logs/rabbitmq"
		system("export RABBITMQ_MNESIA_BASE=#{queueBaseDir}; export RABBITMQ_LOG_BASE=#{queueLogDir}; #{rabbitmq} -detached")
	end	

	desc "qreset", "Resetting the rabbitmq queueing system"
    def qreset() 
        rabbitmqctl = File.dirname(__FILE__) + "/../../../ext/rabbitmq/rabbitmq-server-2.3.1/scripts/rabbitmqctl"
        system("#{rabbitmqctl} force_reset")
    end

    desc "qstop", "Stop the rabbitmq queueing system"
    def qstop() 
        puts "Stopping the rabbitmq queueing system"
        rabbitmqctl = File.dirname(__FILE__) + "/../../../ext/rabbitmq/rabbitmq-server-2.3.1/scripts/rabbitmqctl"
        system("#{rabbitmqctl} stop")
    end

	desc "start", "Start all distributed fuzzing components"
	def start() 
		puts "Started the distributed environment"
		#		%w(queue_start database_start).each |distTask| do
		#			invoke :task
		#		end
	end

	desc "dstop", "Stop all distributed fuzzing components"
	def stop() 
		puts "Stopped the distributed environment"
#		%w(queue_stop, database_stop).each |distTask| do
#			invoke :
#		end
	end
end

