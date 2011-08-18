require 'mamba-refactor'

class Tools < Thor
	namespace :tools
	include Thor::Actions

	check_unknown_options!() 

	desc "seed", "Seed test cases from google searches"
	method_option	:filetype,	:default => "pdf", :aliases => "-f", :desc => "Filetype to download examples (ex. pdf, doc, ppt)", :required => true
	method_option	:num, :default => 10, :type => :numeric, :aliases => "-n", :desc => "Number of files to download", :required => true
	method_option	:terms, :aliases => "-t", :desc => "File containing search terms to mix into test case seeding", :required => false 
	method_option   :zip, :default => false, :type => :boolean, :aliases => "-z", :desc => "Zip the test cases downloaded by the google crawler", :required => false
	# Retrieves test cases from google searches 
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
	end

	# Draw matlab coverage graph of disassembly (Must run this in the top level directory)
	desc "coverage", "Generate a matlab coverage graph"
	method_option	:disassembly,	:default => "", :aliases => "-d", :desc => "IDA Pro Disassembly Library"
	def coverage
		validate_disassembly()
		coverageCalculator = Kernel.const_get("Mamba").const_get("Tools"). const_get("Coverage").new(options[:disassembly])
	end

	no_tasks do
		# Validate the terms filename given against a strict whitelist
		# @param [String] The filename continaing the terms
		def validate_terms(termsFilename)
            if(termsFilename !~ /^\w+\.?\w?$/) then
                say "Error: Incorrect filename format for terms (#{termsFilename})", :red
				say "Error: Must conform to: \w\.?\w? and it must reside in the same directory", :red
                exit(1)
            end
		end

		# Make sure the disassembly file exists
		def validate_disassembly()
			if(!File.exists?(options[:disassembly]) then
                say "Error: Disassembly file (#{termsFilename}) does not exist", :red
				exit(1)
			end
		end
	end
end
