#!/usr/bin/ruby

require 'aws-sdk-ec2'  # v2: require 'aws-sdk'

tag_name = ENV['PT_tag_name']
vpc_id = ENV['PT_vpc_id']

ec2 = Aws::EC2::Resource.new(region: ENV['AWS_REGION'])

igw = ec2.create_internet_gateway

igw.create_tags({ tags: [{ key: 'Name', value: tag_name }]})
igw.attach_to_vpc(vpc_id: vpc_id)

print igw.id