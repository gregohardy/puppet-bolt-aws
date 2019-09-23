#!/usr/bin/ruby

require 'aws-sdk-ec2'  # v2: require 'aws-sdk'
require 'awesome_print'

tag_name = ENV['PT_tag_name']
vpc_id = ENV['PT_vpc_id']

ec2 = Aws::EC2::Resource.new(region: ENV['AWS_REGION'])

subnet = ec2.create_subnet({
  vpc_id: vpc_id,
  cidr_block: '10.200.10.0/24',
  availability_zone: "#{ENV['AWS_REGION']}a"
})

subnet.create_tags({ tags: [{ key: 'Name', value: tag_name}]})
print subnet.id