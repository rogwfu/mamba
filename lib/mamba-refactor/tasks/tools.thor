require 'mamba-refactor'
require 'zip/zip'

class Tools < Thor
	namespace :tools

	desc "seed", "Seed test cases from google searches"
	method_option	:filetype,	:default => "pdf", :aliases => "-f", :desc => "Filetype to download examples (ex. pdf, doc, ppt)", :required => true
	method_option	:num, :default => 10, :aliases => "-n", :desc => "Number of files to download", :required => true
	method_option  :zip, :default => false, :aliases => "-z", :desc => "Zip the test cases downloaded by the google crawler", :required => false
	# Retrieves test cases from google searches 
	def seed()
		say "Downloading test set from Google searches..."
	end

	no_tasks do


	end
end
