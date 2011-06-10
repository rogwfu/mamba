module Mamba
	class Mangle < Fuzzer
        DEFAULT_HEADER_SIZE = 1024
        DEFAULT_NUMBER_CASES = 1024
        DEFAULT_BASE_FILE = "tests/test2"
        DEFAULT_OFFSET = 0 

		# Generates the YAML configuration file for Mangle fuzzer
		def self.generate_config()
                mangleConfig = Hash.new()
                mangleConfig['Basefile'] = Mamba::Mangle::DEFAULT_BASE_FILE
                mangleConfig['Default Offset'] = Mamba::Mangle::DEFAULT_OFFSET
                mangleConfig['Header Size'] = Mamba::Mangle::DEFAULT_HEADER_SIZE
                mangleConfig['Number of Testcases'] = Mamba::Mangle::DEFAULT_NUMBER_CASES
				YAML::dump(mangleConfig)
		end

		# Initializes Mangle fuzzer and the generic fuzzer class
		def initialize(mambaConfig)
			super(mambaConfig)
			@mangleConfig = read_fuzzer_config(self.to_s()) 
            @baseFileSuffix = File.extname(@mangleConfig['Basefile'])

			#
			# Print configuration to log file
			#
			dump_config(@mangleConfig)

			#
            # Seed random number generator
            #
			seed = Time.now.to_i()
            srand(seed)
			@logger.info("SRAND Seed: #{seed}")
		end

		# Runs the fuzzing job
		def fuzz()

			#
			# Check about base test case
			#
			if(!valid_base_test_case?) then
				return()
			end

			# File is fine, open a descriptor for use during fuzzer
			@baseTestCaseFileDes = File.open(@mangleConfig['Basefile'], "rb")

			#
			# Read section of data from base test case
			#
			@sectionData = read_section() 

			#
			# Run all the test cases
			#
			@mangleConfig['Number of Testcases'].times do |testCaseNumber|
				@logger.info("Running testcase: #{testCaseNumber}")
				@reporter.currentTestCase = testCaseNumber
				newTestCaseFilename = mangle_test_case(testCaseNumber)
			    @executor.run(@logger, newTestCaseFilename)
				@reporter.numCasesRun = @reporter.numCasesRun + 1
			end

			# Be Kind, Cleanup
			@baseTestCaseFileDes.close()
		end

		private

		# Create a mangled test case using mangle's algorithm
		# @param [Fixnum] The current number test case being generated
		# @return [String] New test case filename
		def mangle_test_case(testCaseNumber)
			#
			# Extract the necessary section of the file
			#
            secData = clone_section() 

            count = rand(@mangleConfig['Header Size']/10).to_i()

			#
			# Mangle the section data
			#
			count.times do
                offset = rand(@mangleConfig['Header Size'])
                secData[offset] = rand() % 256
                if(rand() % 2 && secData[offset] < 128) then
                    secData[offset] = 0xff
                end
            end

			return(write_test_case(secData, testCaseNumber))
		end

		# Read a section of the base test case to alter
		# @return [Array]  Binary data from the base test case
		def read_section()
			#
			# Set to the configuration fuzzer
			#
			@baseTestCaseFileDes.seek(@mangleConfig['Default Offset'], IO::SEEK_SET)

			#
			# Read in the header
			#
			data = Array.new()
			@mangleConfig['Header Size'].times do |byteNum|
				data << @baseTestCaseFileDes.getc()
			end

			return(data)
		end

		# Make a clone of the original section data (Used to minimize file IO)
		# @return [Array] Copy of original section data
		def clone_section()
			secData = Array.new()
			@sectionData.each do |byte|
				secData << byte
			end
			return(secData)
		end

		# Write a new test case file
		# @param [Array] Mangled data to insert into test case
		# @param [Fixnum] Current number of test case being generated
		# @returns [String] The test case filename
		def write_test_case(sectionData, testCaseNumber)
			testCaseFilename = "tests/#{testCaseNumber}" + @baseFileSuffix

			#
			# Open necessary file descriptors, rewind base descriptor
			#
			testFileDes = File.open(testCaseFilename, "wb")
			@baseTestCaseFileDes.rewind() 

			#
            # Write the beginning of the file
            #
            if(@mangleConfig['Default Offset'] > 0) then
                testFileDes.write(@baseTestCaseFileDes.read(@mangleConfig['Header Size']-1))
            end

            #
            # Write the fuzzed data
            #
            sectionData.each do |byte|
                testFileDes.putc(byte)
            end

            #
            # Write the rest of the base file
            # 
            @baseTestCaseFileDes.seek(@mangleConfig['Header Size'], IO::SEEK_SET)
            testFileDes.write(@baseTestCaseFileDes.read())

			#
			# Cleanup
			#
			testFileDes.close()

			return(testCaseFilename)
		end

		# Ensure the base test case conforms to testing requirements 
		# @return [Bool] True if the base test case is conforms, False otherwise
		def valid_base_test_case?()
            #
            # Check Existence 
            #
            if(!File.exists?(@mangleConfig['Basefile'])) then
                @logger.fatal("Base testcase file: #{@mangleConfig['Basefile']} does not exist")
                @logger.fatal("Exiting....")
				return(false)
            end

			#
            # Error Check Negative/Zero 
            #
            if(@mangleConfig['Default Offset'] < 0 || @mangleConfig['Header Size'] <= 0) then
                @logger.fatal("Either the Header size (#{@mangleConfig['Header Size']}) is <= 0 or the Default Offset (#{@mangleConfig['Default Offset']}) < 0") 
                @logger.fatal("Exiting....")
				return(false)
			end

			#
            # Check for file not having at least the header size
            #
            if(File.stat(@mangleConfig['Basefile']).size < @mangleConfig['Default Offset'] + @mangleConfig['Header Size']) then
                @logger.fatal("Base testcase file: #{@mangleConfig['Basefile']} does contain the minimum number of bytes for the header (#{@mangleConfig['Header Size']})")
                @logger.fatal("Also, you must factor in the beginning offset: #{@mangleConfig['Default Offset']}")
                @logger.fatal("Exiting....")
                return(false)
            end

			return(true)
		end
	end
end
