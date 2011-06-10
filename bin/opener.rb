#!/usr/bin/env ruby
require 'rubygems'
require "appscript"
include Appscript
app.by_pid(ARGV[0].to_i).open(ARGV[1], :wait_reply => FALSE)
