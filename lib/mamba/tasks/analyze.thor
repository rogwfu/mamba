# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'mkmf'
require 'nokogiri'
require 'mongo'

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

	  # Connect to the database
	  dbHandle = Mongo::Connection.new(mambaConfig[:server], mambaConfig[:port]).db(mambaConfig[:uuid])
	  gridHandle = Mongo::Grid.new(dbHandle)
	  enum_traces_distrib(dbHandle, gridHandle)

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


	  # Enumerate all the trace files in the mongo database
	  # @param [Mongo] Handle to the mongo database
	  # @param [Grid] Handle to the Grid Filesystem 
	  def enum_traces_distrib(db, grid)
		normalizedTestCaseNumber = 0
		audit = File.open("analysis/audit.log", File::CREAT|File::TRUNC|File::RDWR)

		fileCol = db["fs.files"]
		fileCol.find({"filename" => /trace\.xml$/}).each do |row|
		  # Write the trace file
		  traceFile = grid.get(row["_id"])
		  localFile = File.open(row['filename'], "wb")
		  localFile.write(traceFile.read())
		  localFile.close()

		  # Check if the trace caused a crash
		  if(crashed?(row['filename'])) then
			#						puts "#{row["_id"]}: #{row['filename']}: Crashed"
			# Get the file extension
			testcase = row['filename'].gsub(/\.trace\.xml/, '')
			newFilename = "%08d%s" % [normalizedTestCaseNumber, File.extname(testcase)]

			# Download the crashing test case
			testcaseFile = grid.get(row["_id"].gsub(/\.trace/, ''))
			localFile = File.open("analysis" + File::SEPARATOR +  newFilename, File::CREAT|File::TRUNC|File::RDWR)
			localFile.write(testcaseFile.read())
			localFile.close()

			# Print some auditing for late
			audit.puts ("#{normalizedTestCaseNumber}: #{row["_id"]}")
			normalizedTestCaseNumber = normalizedTestCaseNumber + 1
		  end

		  # Cleanup download trace file
		  FileUtils.rm(row['filename'])
		end

		audit.close()
	  end
	  # Enumerate all the files in the tests directory
	  def enum_traces()
		normalizedTestCaseNumber = 0
		audit = File.open("analysis/audit.log", File::CREAT|File::TRUNC|File::RDWR)
		Dir.foreach("tests") do |tfile|
		  # Check for an XML trace file
		  if(tfile.match(/\.trace\.xml$/)) then
			if(crashed?("tests" + File::SEPARATOR + tfile)) then
			  tfile.gsub!(/\.trace\.xml/, '')
			  newFilename = "%08d%s" % [normalizedTestCaseNumber, File.extname(tfile)]
			  FileUtils.cp("tests" + File::SEPARATOR + tfile, "analysis" + File::SEPARATOR + newFilename)
			  audit.puts ("#{normalizedTestCaseNumber}: tests/#{tfile}.xml.trace")
			  normalizedTestCaseNumber = normalizedTestCaseNumber + 1
			end
		  end
		end
		audit.close()
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
