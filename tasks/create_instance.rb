#!/usr/bin/ruby

require 'aws-sdk-ec2'  # v2: require 'aws-sdk'
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

def save_inventory(hostname, platform, inventory_location, vars_hash)
  
  if !File.file?("#{inventory_location}/inventory.yaml")
    system "cp templates/inventory.yaml.tmpl #{inventory_location}/inventory.yaml"
  end

  if !File::ALT_SEPARATOR # ruby only sets this on windows private-key: ~/.ssh/id_rsa
    node = { 'name' => hostname,
             'config' => { 'transport' => 'ssh', 'ssh' => { 'user' => 'centos', 'private-key' => "#{ENV['AWS_PRIVATE_KEY']}", 'host-key-check' => false } },
             'facts' => { 'provisioner' => 'aws', 'platform' => platform },
             'vars'  => vars_hash }
    group_name = 'ssh_nodes'
  else
    node = { 'name' => hostname,
             'config' => { 'transport' => 'winrm', 'winrm' => { 'user' => 'Administrator', 'password' => 'Qu@lity!', 'ssl' => false } },
             'facts' => { 'provisioner' => 'vmpooler', 'platform' => platform },
             'vars' => vars_hash }
    group_name = 'winrm_nodes'
  end
  inventory_full_path = './inventory.yaml'
  if inventory_location
    inventory_full_path = File.join(inventory_location, 'inventory.yaml')
  end
  inventory_hash = get_inventory_hash(inventory_full_path)
  add_node_to_group(inventory_hash, node, group_name)
  File.open(inventory_full_path, 'w') { |f| f.write inventory_hash.to_yaml }
  { status: 'ok', node_name: hostname }
end

def provision(node_name, platform, inventory_location, vars)
  include PuppetLitmus::InventoryManipulation
  unless vars.nil?
    vars_hash = YAML.safe_load(vars)
  end
  
  save_inventory(node_name, platform, inventory_location, vars_hash)
end

instance_name = ENV['PT_instance_name']
subnet_id = ENV['PT_subnet_id']
sg_id = ENV['PT_sg_id']
inventory_file = ENV['PT_inventory']
roles = ENV['PT_roles']

ec2 = Aws::EC2::Resource.new(region: ENV['AWS_REGION'])
names_and_roles = JSON.parse(roles)
output = []
names_and_roles.each do |node|
  node['num_create'].times do |n|
    instance = ec2.create_instances({
      image_id: node['image_id'] || 'ami-0ff760d16d9497662',
      min_count: 1,
      max_count: 1,
      key_name: ENV['AWS_KEY_NAME'],
      instance_type: node['instance_type'] || 't2.medium',
      network_interfaces: [{device_index: 0,
        subnet_id: subnet_id,
        groups: [sg_id],
        delete_on_termination: true,
        associate_public_ip_address: true}]
    })

    # Wait for the instance to be created, running, and passed status checks
    ec2.client.wait_until(:instance_running, {instance_ids: [instance.first.id]})

    instance.batch_create_tags({ tags: [{ key: 'Name', value: "#{instance_name}" },{ key: 'role', value: "#{node['role']}" },{ key: 'num', value: "#{n+1}" }, { key: 'lifetime', value: '10d' }]})
    
    i = ec2.instance(instance.first.id)
    provision(i.public_dns_name, 'aws', inventory_file, nil)
    output.push(i.public_dns_name)
  end
end
print output


