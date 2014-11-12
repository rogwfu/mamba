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

# Configure the correct url
# Using 2.0.0 instead of latest due to default exchange usage, for more info:
# http://groups.google.com/group/rabbitmq-discuss/browse_thread/thread/eac656ba68758021?fwc=1
# Use erlang: otp_src_R14B
rabbitmqURL = ""
case RbConfig::CONFIG["host_os"]
when /^darwin(10|11|12)\.\d+(\.\d+)?$/
when /^linux-gnu$/
#	rabbitmqURL = "http://www.rabbitmq.com/releases/rabbitmq-server/v2.3.1/rabbitmq-server-2.3.1.tar.gz"
#	rabbitmqURL = "http://www.rabbitmq.com/releases/rabbitmq-server/v1.7.2/rabbitmq-server-1.7.2.tar.gz"
#	rabbitmqURL = "http://www.rabbitmq.com/releases/rabbitmq-server/v2.0.0/rabbitmq-server-2.0.0.tar.gz"
	rabbitmqURL = "https://www.rabbitmq.com/releases/rabbitmq-server/v3.4.1/rabbitmq-server-3.4.1.tar.gz"
else
	raise "Error: Unsupported Operating System (#{RbConfig::CONFIG["host_os"]})"
end

installDir = ENV['HOME'] +  File::SEPARATOR + ".mamba"
unless File.directory?(installDir)
  FileUtils.mkdir_p(installDir)
end

# Download, Extract, and Make rabbitmq (if needed) - fix for globall installed rabbitmq-server, only use .mamba's
if(!File.exists?("#{installDir}#{File::SEPARATOR}rabbitmq-server-3.4.1")) then
	system("#{tools["curl"]} -o " + installDir + File::SEPARATOR + "rabbitmq-server.tar.gz #{rabbitmqURL}") 
	system("cd #{installDir} ; #{tools["tar"]} xvzf rabbitmq-server.tar.gz")
	system("cd #{installDir}#{File::SEPARATOR}rabbitmq-server-3.4.1 ; make")
end

# Appease packaging library
create_makefile("")
