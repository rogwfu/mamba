module Mamba
	class DistributedMangle < Mangle 

		def initialize(mambaConfig)
			super(mambaConfig)
			@storage = Storage.new(mambaConfig[:server], mambaConfig[:port], mambaConfig[:uuid]) 
			@organizer = mambaConfig[:organizer]
			@logger.info("#{@storage.inspect()}")
		end
		#
		# Overwrite the fuzz function
		#
		def fuzz()
			@logger.info("This is the DistributedMangle fuzz function")
		end
	end
end
