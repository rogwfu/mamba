module Mamba
	class Mangle < Fuzzer
		include Mamba::Tracing

        DEFAULT_HEADER_SIZE = 1024
        DEFAULT_NUMBER_CASES = 1024
        DEFAULT_BASE_FILE = "tests/test2"
        DEFAULT_OFFSET = 0 

		# Generates the YAML configuration file for Mangle fuzzer
		def self.generate_config()
                mangleConfig = Hash.new()
                mangleConfig['Header Size'] = Mamba::Mangle::DEFAULT_HEADER_SIZE
                mangleConfig['Number of Testcases'] = Mamba::Mangle::DEFAULT_NUMBER_CASES
                mangleConfig['Default Offset'] = Mamba::Mangle::DEFAULT_OFFSET
                mangleConfig['Basefile'] = Mamba::Mangle::DEFAULT_BASE_FILE
				YAML::dump(mangleConfig)
		end

		# Initializes Mangle fuzzer and the generic fuzzer class
		def initialize()
			super()
			@mangleConfig = read_fuzzer_config(self.to_s()) 

			#
			# Print configuration to log file
			#
			dump_config(@mangleConfig)
		end

		# Runs the fuzzing job
		def fuzz()

			#
			# Check about base test case
			#
			if(!valid_base_test_case?) then
				return()
			end

			#
			# Run all the test cases
			#
			@mangleConfig['Number of Testcases'].times do |testCaseNumber|
				@logger.info("Running testcase: #{testCaseNumber}")
				@reporter.currentTestCase = testCaseNumber
#				mangle_testcase(testCaseNumber)
#				execute()
				@reporter.numCasesRun = @reporter.numCasesRun + 1
			end
		end

		private

		def read_header()

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
