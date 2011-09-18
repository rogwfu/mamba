require 'mkmf'
require 'socket'

module Mamba
	class Analyze < Thor
		@@version = "0.1.0"
		namespace :analyze

		desc "genetic", "Analyze genetic algorithm crashes"
		def genetic() 

		end

		desc "dgenetic", "Analyze distributed genetic algorithm crashes"
		def dgenetic() 

		end
	end
end
