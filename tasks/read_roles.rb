#!/opt/puppetlabs/puppet/bin/ruby
require 'json'

filepath = ENV['PT_file']

fp = open(filepath, 'r')
raw = fp.read()
print raw.split("\n").join('').delete(' ')