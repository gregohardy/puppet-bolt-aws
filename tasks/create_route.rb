#!/usr/bin/ruby

require 'aws-sdk-ec2'  # v2: require 'aws-sdk'

tag_name = ENV['PT_tag_name']
vpc_id = ENV['PT_vpc_id']
subnet_id = ENV['PT_subnet_id']
ig_id = ENV['PT_ig_id']

puts "GH: subnet #{subnet_id} ig #{ig_id}"

ec2 = Aws::EC2::Resource.new(region: ENV['AWS_REGION'])

table = ec2.create_route_table({
    vpc_id: vpc_id
})

table.create_tags({ tags: [{ key: 'Name', value: tag_name }]})

table.create_route({
  destination_cidr_block: '0.0.0.0/0',
  gateway_id: ig_id
})

table.associate_with_subnet({
  subnet_id: subnet_id
})

print table.id