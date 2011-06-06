module Mamba
	class Mangle < Fuzzer

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
		end

		# Runs the fuzzing job
		def fuzz()

		end
	end
end
