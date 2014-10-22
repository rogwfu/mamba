require 'mkmf'
require 'fileutils'

# Check for required tools
tools = Hash.new()
%w(curl tar).each do |toolName|
	toolLoc = find_executable(toolName)
	if(!toolLoc) then
		raise "Error: #{toolName} not found in #{ENV['PATH']}"
	else
		tools[toolName] = toolLoc
	end
end

# Configure the correct url
case RbConfig::CONFIG["host_os"]
when /^darwin(10|11|12|13|14)\.\d+(\.\d+)?$/
when /^linux-gnu$/
else
	raise "Error: Unsupported Operating System (#{RbConfig::CONFIG["host_os"]})"
end

# Copy the files to the local path (need to make this more dynamic
installDir = ENV['HOME'] +  File::SEPARATOR + ".mamba"
unless File.directory?(installDir)
  FileUtils.mkdir_p(installDir)
end

# Copy useful scripts
FileUtils.cp(File.dirname(__FILE__) + "/lldb-func-tracer.py", installDir, :verbose => true)
FileUtils.cp(File.dirname(__FILE__) + "/lldbutil.py", installDir, :verbose => true)

# Appease packaging library
create_makefile("")
