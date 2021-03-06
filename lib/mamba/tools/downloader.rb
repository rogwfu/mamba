require 'cgi'
require 'open-uri'
require 'hpricot'
require 'mkmf'
require 'digest/sha2'
require 'zip/zip'

module Mamba
  module Tools
	# Class To download files from google
	class Downloader
	  # Create an instance of the Downloader class
	  # @param [String] Filename of a file containing search terms (1 per line)
	  def initialize(termFilename)
		# Create a hash to hold all signatures
		@fileSignatures = Hash.new()

		srand(Time.now().to_i)

		# Try to find wget for faster download
		wget = find_executable("wget")

		# Write the corresponding lambda based on capabilities
		if(wget == nil) then
		  @downloader =  lambda do |filename, href|
			fh = File.open(filename, "w+") do
			  open(href) do |fileUrl|
				fh.write(fileUrl.read())
			  end
			end
		  end
		else
		  @downloader = lambda do |filename, href|
			system("wget -O #{filename} -U \"Mozilla/5.0 (X11; U; Linux i686; pl-PL; rv:1.9.0.2) Gecko/20121223 Ubuntu/9.25 (jaunty) Firefox/3.8\"--timeout=120 \"#{href}\"")
		  end	
		end

		# Read in some terms to spice it up
		if(termFilename) then
		  @searchTerms = parse_terms(termFilename)
		else
		  @searchTerms = [CGI::escape(" ")] 
		end

		return(self)
	  end

	  # Download a file
	  # @param [Fixnum] The number of files requested to download 
	  # @param [String] File suffix to append to filenames during normalization
	  def download(numRequestedFiles, fileSuffix)
		docsCollected = 0
		while docsCollected < numRequestedFiles do
		  # Create the base url
		  url = "http://www.google.com/search?q=#{@searchTerms[rand(@searchTerms.length())]}#{CGI::escape(' ')}filetype:#{fileSuffix}&filter=0"

		  # 1000 is the maximum returned by a google search
		  doc = Hpricot(open(url + "&start=" + rand(1000).to_s()).read)

		  pageLimit = 0
		  # Download all the files on the page
		  (doc/"li[@class='g']").each do |li|

			# Check for reaching threshold
			if(docsCollected >= numRequestedFiles or pageLimit == 3) then
			  break
			end

			# Check th filetype
			filetype = li.search("span[@class='f']") 
			if(filetype.nil?) then
			  next	
			end

			# Pull out the download link
			# link = li.search("a[@class='l']")
			link = (li/"a")
			if(link.nil?) then
			  next
			end

			# Remove new syntax added to links
			downloadLink = link.first.attributes['href'].gsub("/url?q=", "").split("&")[0]

			# Debugging
			exemplarName = "#{docsCollected}.#{fileSuffix}"
			puts "-----------------------------"
			puts "#{exemplarName}:#{downloadLink}"
			puts "-----------------------------"

			# Download the file
			@downloader.call(exemplarName, downloadLink)	

			# Check for uniqueness
			exemplarHash = hash(exemplarName)
			if(downloaded?(exemplarHash) or File.stat(exemplarName).size == 0) then
			  FileUtils.rm(exemplarName)
			else
			  @fileSignatures[exemplarHash] = true
			  docsCollected +=  1
			  pageLimit += 1
			end
		  end
		end
	  end

	  # Zip all the downloaded test cases
	  # @param [String] File extension of files searched for on google
	  def zip(filetype)
		# Remove old testset
		if(File.exists?("testset.zip")) then
		  puts "Warning: Erasing existing testset.zip"
		  FileUtils.rm("testset.zip")
		end

		# Create an archive 
		Zip::ZipFile.open("testset.zip", Zip::ZipFile::CREATE) do |zipfile|
		  entries = Dir.glob("*.#{filetype}")
		  entries.each do |entry|
			zipfile.add(entry, entry)
		  end
		end
	  end

	  private

	  # Parse the terms in the file
	  # @param [String] The name of the search term file
	  # @return [Array] An array of search terms
	  def parse_terms(termFilename)

		# Error Check 
		if(!File.exists?(termFilename))
		  puts "Error: File #{termFilename} does not exist!"
		  exit(1)
		end

		terms = Array.new()
		File.open(termFilename, 'r') do |fileHandler|
		  fileHandler.each_line do |line|
			terms << CGI::escape(line.chomp())
		  end
		end
		return(terms)
	  end

	  # Hash the file just downloaded
	  # @param [String] Downloaded file's name
	  # @return [String] SHA256 hex digest of the file
	  def hash(filename)
		# Hash the file
		return(Digest::SHA256.file(filename).hexdigest())
	  end

	  # Hash lookup to determine if the file already exists
	  # @param [String] Hex digest of a file
	  # @returns [Boolean] Whether the file exists or not
	  def downloaded?(hexDigest)
		# Check to see if file already downloaded
		if(@fileSignatures.has_key?(hexDigest)) then
		  return(true)
		else
		  return(false)
		end
	  end
	end
  end
end
