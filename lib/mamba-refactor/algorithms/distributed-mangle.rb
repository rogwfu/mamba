module Mamba
	class DistributedMangle < Mangle 
		#
		# Overwrite the fuzz function
		#
		def fuzz()
			@logger.info("This is the DistributedMangle fuzz function")
		end
	end
end
