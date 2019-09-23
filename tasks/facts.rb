#!/usr/bin/ruby

require 'open3'

fact_name = ENV['PT_fact_name']

_, stdout, stderr = Open3.popen3("facter #{fact_name}")

print stdout.read.strip