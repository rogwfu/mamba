# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'mamba'

class Tools < Thor
  IDAPro   = Shellwords.shellescape(ENV['IDA']) 
  IDAPro64 = Shellwords.shellescape(ENV['IDA64'])

  namespace :tools
  include Thor::Actions

  check_unknown_options!() 

  # Draw matlab coverage graph of disassembly (Must run this in the top level directory)
  desc "coverage", "Generate a matlab coverage graph"
  method_option	:disassembly,	:default => "", :aliases => "-d", :desc => "IDA Pro Disassembly Library"
  def coverage
	validate_existence(options[:disassembly])
	coverageCalculator = Kernel.const_get("Mamba").const_get("Tools"). const_get("Coverage").new(options[:disassembly])
  end


  # Runs IDA Pro auto analysis and extracts the information in YAML serialization format 
  # Ida Options: -A autonomous mode. IDA will not display dialog boxes.
  #              -S Execute a script file when the database is opened. 
  #              -o specify the output database (implies -c)
  # http://www.hex-rays.com/idapro/idadoc/417.shtml 
  desc "disassemble", "Extract disassembly information from IDA Pro into YAML serialization format"
  method_option :object, :type => :string, :default => "", :aliases => "-o", :desc => "Executable or shared library to disassembly and extract"
  method_option :architecture, :type => :boolean, :default => false, :aliases => "-a", :desc => "Turn 64 bit support on"
  method_option :ida, :type => :string, :default => "", :aliases => "-i", :desc => "Set a different IDA Pro path"
  def disassemble()
	ida = validate_ida()
	validate_existence(options[:object])
	destination = "disassemblies" + File::SEPARATOR + options[:object].split(File::SEPARATOR)[-1]
	idaAnalysisScript = find_autoanalysis_script()
	say "Info: Disassembling and serializing #{options[:object]}...", :blue
	# Need to whitelist options[:object] (this is ugly code)
	say "#{ida} -A  -S\"#{idaAnalysisScript}\" -o#{destination} \"#{options[:object]}\""
	system("#{ida} -A  -S\"#{idaAnalysisScript}\" -o#{destination} \"#{options[:object]}\"")
	say "Info: Disassembling and serialization complete.", :blue
  end

  # Wrapper around otool to iterrogate an object for all shared objects linked against it 
  desc "deps", "List dynamic dependencies for an executable or object"
  method_option	:object, :type => :string, :default => "", :aliases => "-o", :desc => "Executable or shared library to examine with otool"
  method_option	:architecture, :type => :boolean, :default => false, :aliases => "-a", :desc => "Turn 32 bit support on"
  def deps()
	validate_existence(options[:object])

	cmd = nil

	# Instantiate the correct class
	case RbConfig::CONFIG["host_os"]
	when /^darwin(10|11|12|13|14)\.\d+(\.\d+)?$/
	  cmd = Kernel.const_get("Mamba").const_get("Tools").const_get("OTool").new(options[:object], options[:architecture])
	when /^linux-gnu$/
	  cmd = Kernel.const_get("Mamba").const_get("Tools").const_get("LDD").new(options[:object], options[:architecture])
	else
	  say "Error: Unsupported Operating System (#{RbConfig::CONFIG["host_os"]})", :red
	  exit(1)
	end

	# Find all the shared libraries
	cmd.gather_shared_libraries()
	puts cmd.libraries
	cmd.libraries do |sharedObject| 
	  say "#{sharedObject}", :blue
	end
  end

  # Retrieves test cases from google searches 
  desc "seed", "Seed test cases from google searches"
  method_option   :clean, :default => false, :type => :boolean, :aliases => "-c", :desc => "Cleanup downloaded files, since they are zipped"
  method_option	:filetype,	:default => "pdf", :aliases => "-f", :desc => "Filetype to download examples (ex. pdf, doc, ppt)"	#, :required => true
  method_option	:num, :default => 10, :type => :numeric, :aliases => "-n", :desc => "Number of files to download"				#, :required => true
  method_option	:terms, :aliases => "-t", :desc => "File containing search terms to mix into test case seeding", :required => false 
  method_option   :zip, :default => false, :type => :boolean, :aliases => "-z", :desc => "Zip the test cases downloaded by the google crawler", :required => false
  def seed()
	say "Downloading test set from Google searches...", :blue

	validate_terms(options[:terms]) if options[:terms]

	# Create a downloader and download files
	googler = Kernel.const_get("Mamba").const_get("Tools"). const_get("Downloader").new(options[:terms])
	googler.download(options[:num], options[:filetype])

	# Create an archive 
	if(options[:zip]) then
	  googler.zip(options[:filetype])
	end

	# Cleanup the directory
	if(options[:zip] and options[:clean]) then
	  cleanup()
	end

	# Remove residual mkmf.log
	remove_file("mkmf.log")
  end

  no_tasks do
	def find_autoanalysis_script()
	  analysisScript = find_executable0("func-auto.py")
	  if(analysisScript == nil) then
		say "Error: Analysis script (func-auto.py) not found in #{ENV['PATH']}", :red
		exit(1)
	  end
	  return(Gem.bin_path('plympton', 'func-auto.py'))
	end

	# Make sure the requested file exists
	# @param [String] The filename to check for existence
	def validate_existence(filename)
	  #			if(!File.exists?("#{filename}")) then
	  #                say "Error: File (#{filename}) does not exist", :red
	  #				exit(1)
	  #			end
	end

	# Make sure IDA Pro is installed for this tool to work 
	def validate_ida()
	  # Check for custom IDA Pro installed
	  if(!options[:ida].empty?()) then
		validate_existence(options[:ida])
		if(!File.executable?(options[:ida])) then
		  say "Error: File (#{options[:ida]}) is not executable", :red
		  exit(1)
		end
		return(options[:ida])
	  else
		# Check for the different architectures
		if(!options[:architecture]) then
		  validate_existence(IDAPro)
		  return(IDAPro)
		else
		  validate_existence(IDAPro64)
		  return(IDAPro64)
		end
	  end
	end

	# Validate the terms filename given against a strict whitelist
	# @param [String] The filename continaing the terms
	def validate_terms(termsFilename)
	  if(termsFilename !~ /^\w+\.?\w?$/) then
		say "Error: Incorrect filename format for terms (#{termsFilename})", :red
		say "Error: Must conform to: \w\.?\w? and it must reside in the same directory", :red
		exit(1)
	  end
	end

	# Cleanup the downloaded files since a zip file already has the tests 
	def cleanup()
	  Dir.glob("*.#{options[:filetype]}").each do |downloadedFile|
		remove_file(downloadedFile)
	  end
	end
  end
end
