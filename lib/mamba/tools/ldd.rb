module Mamba
  module Tools
	# Class to work with otool 
	class LDD 
	  attr_reader :libraries
	  attr_reader :obj

	  # Create an instance of the coverage class
	  # @param [String] Path of the object file to interrogate
	  # @param [Boolean] Enable 64 bit architecture support
	  # @returns nil if otool is not found
	  def initialize(objectFile, architecture)
		@ldd = find_executable0('ldd')
		if(@ldd == nil) then
		  return(nil)
		end

		@obj = objectFile
		@libraries = Array.new()	

		# Hack for now, please convert to regex
		executablePathArr = objectFile.split(File::SEPARATOR)
		executablePathArr.pop()
		@executablePath = executablePathArr.join(File::SEPARATOR)
	  end

	  # Reads the shared libraries from an objects macho header
	  # @returns [Hash] All shared libraries found
	  def gather_shared_libraries()

		output = ""
		# Find all rpath commands 
		ret = IO.popen("#{@ldd} -v \"#{@obj}\"", 'r') do |f|
		  output = f.read()
		end

		cmdOutput = output.split("\n")
		cmdOutput.each do |line|
		  case line
		  when /:/
#			puts line.split(":")[0].chomp() 
			lib = line.split(":")[0].strip() 
			if not lib.include?("Version information") then
			  @libraries << lib
			end
		  when /=>/
#			puts "Line: #{line}"
#			puts line.split("=>")[1].split("(")[0].strip() 
			lib = line.split("=>")[1].split("(")[0].strip() 
			if not lib.empty? then
			  @libraries << lib
			end
		  else
		  end

		  # All keep unique entries
		  @libraries.uniq!

		end
	  end
	end
  end
end
