require 'mkmf'
require 'socket'
require 'nokogiri'

module Mamba
	class Analyze < Thor
		@@version = "0.1.0"
		namespace :analyze

		desc "genetic", "Analyze genetic algorithm crashes"
		def genetic() 
			mambaConfig = read_config()
			error_check_type(mambaConfig)
			puts mambaConfig.inspect()
		end

		desc "dgenetic", "Analyze distributed genetic algorithm crashes"
		def dgenetic() 
			mambaConfig = read_config()
			error_check_type(mambaConfig, true)
			puts mambaConfig.inspect()
		end

		no_tasks do
			# Reads the Mamba configuration file from the current environment
			# @return [Hash] configuration settings
			def read_config()
				config = YAML.load_file("configs#{File::SEPARATOR}Mamba.yml")
				return(config)
			end
			# Reads the Mamba configuration file from the current environment
			# @param [Boolean] Distributed Framework or not
			def error_check_type(mambaConfig, distributed=false)
				# See if the check should be for a distributed framework
				if(distributed) then
					if(!mambaConfig[:type].match(/^Distributed/)) then
						say "Error: Type is not distributed: #{mambaConfig[:type]}!", :red
					end
				else 
					if(mambaConfig[:type].match(/^Distributed/)) then
						say "Error: Type should not be distributed: #{mambaConfig[:type]}!", :red
					end
				end
			end
		end
	end
end
