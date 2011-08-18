require 'mamba-refactor'

class Tools < Thor
	namespace :tools
	include Thor::Actions

	check_unknown_options!() 

	desc "seed", "Seed test cases from google searches"
	method_option   :clean, :default => false, :type => :boolean, :aliases => "-c", :desc => "Cleanup downloaded files, since they are zipped"
	method_option	:filetype,	:default => "pdf", :aliases => "-f", :desc => "Filetype to download examples (ex. pdf, doc, ppt)"	#, :required => true
	method_option	:num, :default => 10, :type => :numeric, :aliases => "-n", :desc => "Number of files to download"				#, :required => true
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

		# Cleanup the directory
		if(options[:zip] and options[:clean]) then
			cleanup()
		end

		# Remove residual mkmf.log
		remove_file("mkmf.log")
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

		# Cleanup the downloaded files since a zip file already has the tests 
		def cleanup()
			Dir.glob("*.#{options[:filetype]}").each do |downloadedFile|
				remove_file(downloadedFile)
			end
		end
	end
end
