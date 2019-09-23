#!/usr/bin/ruby

require 'aws-sdk-ec2'  # v2: require 'aws-sdk'

tag_name = ENV['PT_tag_name']

ec2 = Aws::EC2::Resource.new(region: ENV['AWS_REGION'])

vpc = ec2.create_vpc({ cidr_block: '10.200.0.0/16' })
# So we get a public DNS
vpc.modify_attribute({
  enable_dns_support: { value: true }
})

vpc.modify_attribute({
  enable_dns_hostnames: { value: true }
})

# Name our VPC
vpc.create_tags({ tags: [{ key: 'Name', value: tag_name }]})
print vpc.vpc_id