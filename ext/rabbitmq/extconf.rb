require 'mkmf'

#
# Check for required tools
#
tools = Hash.new()
%w(curl tar erl).each do |toolName|
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
rabbitmqURL = ""
case Config::CONFIG["host_os"]
when /^darwin10\.\d+(\.\d+)?$/
#	rabbitmqURL = "http://www.rabbitmq.com/releases/rabbitmq-server/v2.3.1/rabbitmq-server-2.3.1.tar.gz"
	rabbitmqURL = "http://www.rabbitmq.com/releases/rabbitmq-server/v1.7.2/rabbitmq-server-1.7.2.tar.gz"
else
	raise "Error: Unsupported Operating System (#{Config::CONFIG["host_os"]})"
end

#
# Download, Extract, and Make rabbitmq (if needed)
#
if(!find_executable("rabbitmq-server")) then
	system("#{tools["curl"]} -O #{rabbitmqURL}") 
	system("#{tools["tar"]} xvzf #{rabbitmqURL.split('/')[-1]}")
	system("cd #{rabbitmqURL.split('/')[-1].gsub(/\.tar\.gz$/, "")} ; make ")
end

#
# Appease packaging library
#
create_makefile("")
