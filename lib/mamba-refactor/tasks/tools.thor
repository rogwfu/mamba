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
		
		# Create a downloader and download files
		googler = Kernel.const_get("Mamba").const_get("Tools"). const_get("Downloader").new(options[:terms])
		googler.download(options[:num], options[:filetype])

		# Create an archive 
		if(options[:zip]) then
			googler.zip(options[:filetype])
		end
	end
end
