#!/usr/bin/ruby

# Assumptions. 
# You have tagged your resources with a common tag. This tag is passed by the ENV var below.
# The security group name is the tag_name as well.

require 'aws-sdk-ec2'
require 'ap'
require 'json'
require 'net/http'
require 'yaml'
require 'puppet_litmus'
require 'pry'


def get_inventory_hash(inventory_full_path)
  if File.file?(inventory_full_path)
    inventory_hash_from_inventory_file(inventory_full_path)
  else
    { 'groups' => [{ 'name' => 'docker_nodes', 'nodes' => [] }, { 'name' => 'ssh_nodes', 'nodes' => [] }, { 'name' => 'winrm_nodes', 'nodes' => [] }] }
  end
end

def remove_node_from_inventory(node_name, inventory_location)
  inventory_full_path = File.join(inventory_location, 'inventory.yaml')
  if File.file?(inventory_full_path)
    inventory_hash = inventory_hash_from_inventory_file(inventory_full_path)
    remove_node(inventory_hash, node_name)
  end
  puts "Removed #{node_name}"
  File.open(inventory_full_path, 'w') { |f| f.write inventory_hash.to_yaml }
  { status: 'ok' }
end

tag_name = ENV['PT_tag_name']
inventory_file = ENV['PT_inventory']

ec2 = Aws::EC2::Resource.new(region: ENV['AWS_REGION'])
client = Aws::EC2::Client.new(region: ENV['AWS_REGION'])

include PuppetLitmus::InventoryManipulation

ec2.instances({filters: [{name: 'tag:Name', values: [tag_name]}]}).each do |i|
  if i.exists?
    case i.state.code
    when 48  # terminated
      puts "#{i.id} is already terminated"
    else
      puts "#{i.id} terminating"
      devices = i.block_device_mappings
      i.terminate
      i.wait_until_terminated

      # delete the ebs volumes
      devices.each do |device|
        client.delete_volume({
          volume_id: device.ebs.volume_id, 
        })
      end
      # Update the inventory file
      remove_node_from_inventory(i.public_dns_name, inventory_file)
    end
  end
end

route_tables = ec2.route_tables({
  filters: [
    {
      name: "tag:Name",
      values: [tag_name],
    },
  ]
})

subnets = ec2.subnets({
  filters: [
    {
      name: "tag:Name",
      values: [tag_name],
    },
  ]
})

igws = ec2.internet_gateways({
  filters: [
    {
      name: "tag:Name",
      values: [tag_name],
    },
  ]
})

sgs = ec2.security_groups()
vpcs = ec2.vpcs ({
  filters: [
    {
      name: "tag:Name",
      values: [tag_name],
    },
  ]
})

# Lets watch the world burn

puts "Deleting subnets"
subnets.each do |subnet|
  puts "Deleting [#{subnet.id}]"
  resp = client.delete_subnet({
    subnet_id: subnet.id, 
  })
end

puts "Deleting igws"
igws.each do |ig| 
  ig.attachments.each do |vpc|
    puts "Detach ig [#{ig.id}] from vpc [#{vpc.vpc_id}]"
    ig.detach_from_vpc({vpc_id: vpc.vpc_id})
  end
  puts "Delete ig [#{ig.id}]"
  resp = client.delete_internet_gateway({
    internet_gateway_id: ig.id, 
  })
end

puts "Deleting route tables"
route_tables.each do |rt|
  puts "Delete route table [#{rt.id}]"
  client.delete_route_table({route_table_id: rt.id})
end

puts "Deleting security_groups"
sgs.each do |sg|
  if sg.group_name == tag_name
    puts "Delete sg [#{sg.group_id}]"
    client.delete_security_group({group_id: sg.group_id})
  end
end

puts "Deleting vpcs"
vpcs.each do |vpc|
  puts "Delete vpc [#{vpc.vpc_id}]"
  resp = client.delete_vpc({vpc_id: vpc.vpc_id})
end
