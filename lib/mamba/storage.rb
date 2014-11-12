require 'mongo'

module Mamba
	class Storage
		attr_accessor :dbHandle
		attr_accessor :database

		# @param [String]
		# @port  [String]
		# @uuid  [String]
		def initialize(server, port, uuid)
        	# Setup the Mongodb Connections
        	@database = Mongo::MongoClient.new(server, port).db(uuid)
        	@dbHandle = Mongo::Grid.new(@database)
		end
	end
end
