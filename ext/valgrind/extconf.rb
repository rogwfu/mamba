require 'mkmf'

#
# Check for required tools
#
tools = Hash.new()
%w(svn patch make).each do |toolName|
	toolLoc = find_executable(toolName)
	if(!toolLoc) then
		raise "Error: #{toolName} not found in #{ENV['PATH']}"
	else
		tools[toolName] = toolLoc
	end
end
valgrindTag = "VALGRIND_3_6_1"

puts "===== Pulling valgrind tag: #{valgrindTag} ====="
system("#{tools["svn"]} co svn://svn.valgrind.org/valgrind/tags/#{valgrindTag} trunk")
#system("cp -R /tmp/trunk .")

puts "===== Patching Valgrind ====="
system("cp ../../valgrind-patches/*.patch trunk/")
system("cd trunk ; #{tools["patch"]} -p0 < rufus.3.6.1.patch")
system("cd trunk ; #{tools["patch"]} -p0 < signals.patch")

puts "===== Building Valgrind ====="
#system("cd trunk ; ./autogen.sh ; ./configure --enable-only32bit --prefix=`pwd`/inst")
system("cd trunk ; ./autogen.sh ; ./configure --prefix=`pwd`/inst")
system("cd trunk ; #{tools["make"]}; #{tools["make"]} install")

# Appease packaging library
create_makefile("")



#system("cd trunk ; #{tools["patch"]} -p0 < callgrind.3.6.1.patch")
