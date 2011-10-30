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
case RbConfig::CONFIG["host_os"]
when /^darwin10\.\d+(\.\d+)?$/
	mongodURL = "http://fastdl.mongodb.org/osx/mongodb-osx-x86_64-1.8.2-rc3.tgz"
else
	raise "Error: Unsupported Operating System (#{RbConfig::CONFIG["host_os"]})"
end

#
# Download and Extract mongod (if necessary)
#
if(!find_executable("mongod")) then
	system("#{tools["curl"]} -O #{mongodURL}") 
	system("#{tools["tar"]} xvzf #{mongodURL.split('/')[-1]}")
end

#
# Appease packaging library
#
create_makefile("")
