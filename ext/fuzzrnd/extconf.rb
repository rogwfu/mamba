require 'mkmf'

dir_config("fuzzrnd")
have_library("c", "main")

case RUBY_VERSION
when /\A1\.8/
      $CFLAGS += ' -DRUBY_1_8_x'
when /\A1\.9/
      $CFLAGS += ' -DRUBY_1_9_x'
when /\A2\.1/
      $CFLAGS += ' -DRUBY_2_1_x'
else
      raise "unsupported Ruby version: #{RUBY_VERSION}"
end

create_makefile("fuzzrnd")
