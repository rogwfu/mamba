require 'mkmf'

#
# Check for required tools
#
tools = Hash.new()
%w(curl tar).each do |toolName|
	toolLoc = find_executable(toolName)
	if(!toolLoc) then
		raise "Error: #{toolName} not found in #{ENV['PATH']}"
	else
		tools[toolName] = toolLoc
	end
end

#
# Configure the correct url
#
mongodURL = ""
case Config::CONFIG["host_os"]
when /^darwin10\.\d+\.\d+$/
	mongodURL = "http://fastdl.mongodb.org/osx/mongodb-osx-x86_64-1.6.5.tgz"
else
	raise "Error: Unsupported Operating System (#{Config::CONFIG["host_os"]})"
end

#
# Download and Extract mongod
#
system("#{tools["curl"]} -O #{mongodURL}") 
system("#{tools["tar"]} xvzf #{mongodURL.split('/')[-1]}")

#
# Appease packaging library
#
create_makefile("")
