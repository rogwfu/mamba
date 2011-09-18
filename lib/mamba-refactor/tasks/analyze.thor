require 'mkmf'
require 'nokogiri'

module Mamba
	class Analyze < Thor
		@@version = "0.1.0"
		namespace :analyze

		desc "genetic", "Analyze genetic algorithm crashes"
		def genetic() 
			error_check_root()
			mambaConfig = read_config()
			error_check_type(mambaConfig)
			enum_traces()
		end

		desc "dgenetic", "Analyze distributed genetic algorithm crashes"
		def dgenetic() 
			error_check_root()
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
						exit(1)
					end
				else 
					if(mambaConfig[:type].match(/^Distributed/)) then
						say "Error: Type should not be distributed: #{mambaConfig[:type]}!", :red
						exit(1)
					end
				end
			end

			# Determine if the task being run from the root directory 
			def error_check_root()
				if(!File.exists?("configs")) then
					say "Error: No configs directory exsits: #{Dir.pwd()}!", :red
					exit(1)
				end
			end

			# Enumerate all the files in the tests directory
			def enum_traces()
				Dir.foreach("tests") do |tfile|
					# Check for an XML trace file
					if(tfile.match(/\.trace\.xml$/)) then
						if(crashed?("tests" + File::SEPARATOR + tfile)) then
							puts "Filename is: #{tfile}"
						end
					end
				end
			end

			# Determine if the trace file contains a crash
			# @param [String] The name of the xml trace file
			def crashed?(traceFile)
			    # Open the valgrind xml trace file
				xmlFile = File.open(traceFile, "r")
				xmlDoc = Nokogiri::XML(xmlFile)
				fault = xmlDoc.xpath("//fault")

				# Check for a stack trace
				if(!fault.empty?()) then
					return(true)
				end

				return(false)
			end
		end
	end
end
