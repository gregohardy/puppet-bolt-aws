#!/usr/bin/ruby

require 'aws-sdk-ec2'  # v2: require 'aws-sdk'

group_name = ENV['PT_group_name']
vpc_id = ENV['PT_vpc_id']

ec2 = Aws::EC2::Resource.new(region: ENV['AWS_REGION'])

sg = ec2.create_security_group({
  group_name: group_name,
  description: 'Security group for your splunk test framework',
  vpc_id: vpc_id
})

sg.authorize_ingress({
  ip_permissions: [{
    ip_protocol: 'tcp',
    from_port: 22,
    to_port: 22,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  {
    ip_protocol: 'tcp',
    from_port: 80,
    to_port: 80,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  {
    ip_protocol: 'tcp',
    from_port: 443,
    to_port: 443,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  {
    ip_protocol: 'tcp',
    from_port: 4433,
    to_port: 4433,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  { # splunk
    ip_protocol: 'tcp',
    from_port: 8000,
    to_port: 8000,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  { # splunk
    ip_protocol: 'tcp',
    from_port: 8088,
    to_port: 8088,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  {
    ip_protocol: 'tcp',
    from_port: 8140,
    to_port: 8140,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  {
    ip_protocol: 'tcp',
    from_port: 8142,
    to_port: 8142,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  {
    ip_protocol: 'tcp',
    from_port: 8170,
    to_port: 8170,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  },
  {
    ip_protocol: 'tcp',
    from_port: 61613,
    to_port: 61613,
    ip_ranges: [{
      cidr_ip: '0.0.0.0/0'
    }]
  }]
})

print sg.id