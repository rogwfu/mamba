module Mamba
	module Tools
		# Class to work with otool 
		class OTool 
			# Create an instance of the coverage class
			# @param [String] Path of the object file to interrogate
			# @param [Boolean] Enable 64 bit architecture support
			# @returns nil if otool is not found
			def initialize(objectFile, architecture)
				@otool = find_executable0('otool')
				if(@otool == nil) then
					return(nil)
				end

				@needed = [objectFile]
				@found = Hash.new()

				# Hack for now, please convert to regex
				executablePathArr = objectFile.split(File::SEPARATOR)
				executablePathArr.pop()
				@executablePath = executablePathArr.join(File::SEPARATOR)

                # Setup architecture preference
                if(architecture) then
                    @architecture = "x86_64"
                else
                    @architecture = "i386"
                end

				# Stash all rpath commands for latter reference 
				@rpathCommands = Array.new()	
			end

			# Reads the shared libraries from an objects macho header
			# Note collapse this down to one pass for rpath command and load commands
			def read_header()
				# Pull an object off the array
				object = @needed.shift()
				@found[object] = true

				output = ""


				# Find all rpath commands 
				ret = IO.popen("#{@otool} -arch #{@architecture} -l \"#{object}\"", 'r') do |f|
					output = f.read()
				end

				loadCommands = output.split("\n")
				loadCommands.each_index do |idx|
					if(loadCommands[idx].include?("cmd LC_RPATH")) then
						rpath = loadCommands[idx+2]
						rpath.gsub!(/^\s+path\s*/, "")
						rpath.gsub!(/\s+\(.*?\)\s*/, "")

						# Quick hack to fix executable path in load path
						if(rpath.start_with?("@executable_path")) then
							rpath.gsub!(/@executable_path/, @executablePath)
						end

						@rpathCommands << rpath
					end
				end

				# Find all shared libraries linked with the object 
				ret = IO.popen("#{@otool} -arch #{@architecture} -L \"#{object}\"", 'r') do |f|
					output = f.read()
				end

				# Cleanup the output 
				linkedObjects = output.split("\n")
				linkedObjects.shift()

				# Cleanup the entries
				linkedObjects.each do |sharedObject|
					sharedObject.sub!(/\(.*\)/, '').strip!().chomp!()

					# Fix executable path variable in load command
					if(sharedObject.start_with?("@executable_path")) then
						sharedObject.gsub!(/@executable_path/, @executablePath)
					end

					# Fix rpath variable in load command
					if(sharedObject.start_with?("@rpath")) then
						sharedObject = fixup_rpath(sharedObject)
					end

					if(!@found.has_key?(sharedObject)) then
						@needed.push(sharedObject)
					end
				end
			end

			# Fixup an load command using rpath with the full path 
			# @param [String] Object from the load commands
			# @returns [String] Fully quantified path for the shared object
			def fixup_rpath(sharedObject)
				# Remove the rpath
				sharedObject.gsub!(/@rpath/, "")
			
				# Try different rpaths
				@rpathCommands.each do |rpath|
					objectFullPath = rpath + sharedObject
					if(File.exists?(objectFullPath)) then		
						return(objectFullPath)	
					end
				end

				# Error case (couldn't find it so return with the @rpath)
				return("@rpath" + sharedObject)
			end

			# Start recursively interrogating object files with otool
			# @returns [Hash] All shared libraries found
			def gather_shared_libraries()
				begin
					read_header()
				end while(@needed.size() != 0)

				return(@found.keys.sort())
			end
		end
	end
end
