# puppet-bolt-aws

A series of Puppet bolt plans and tasks to launch Amazon AWS infrastructure.
The provision plan will create a single VPC, subnet, internet gateway, security_group
and route table for you. Any instances that are create will be affiliated with the VPC.

## Credentials setup

You will need to export your AWS credentials, region and private key file:

```bash
export AWS_ACCESS_KEY_ID = 'xxxxxxx'
export AWS_SECRET_ACCESS_KEY = 'yyyyyyy'
export AWS_REGION = 'eu-west-1'
export AWS_PRIVATE_KEY=~/.ssh/<your pem file>.pem
```

## Setup

```bash
bundle install --path .bundle/gems
```

## Available Puppet Plans

```bash
$ bundle exec bolt plan show
puppet_bolt_aws::deprovision
puppet_bolt_aws::provision

MODULEPATH:
/Users/greghardy/.puppetlabs/bolt-code/modules:/Users/greghardy/.puppetlabs/bolt-code/site-modules:/Users/greghardy/.puppetlabs/etc/code/modules:/Users/greghardy/demo
```

## Available Puppet Tasks
```bash
$ bundle exec bolt task show
puppet_bolt_aws::create_instance                                                     This task creates an AWS instance
puppet_bolt_aws::create_internet_gateway                                             This task creates an AWS Internet Gateway
puppet_bolt_aws::create_route                                                        This task creates an AWS Internet Gateway
puppet_bolt_aws::create_security_group                                               This task creates an AWS security group
puppet_bolt_aws::create_subnet                                                       This task creates an AWS subnet
puppet_bolt_aws::create_vpc                                                          This task creates an AWS subnet
puppet_bolt_aws::delete_aws                                                          This task creates an delete's all aws EC2 and VPC resources for a given tag

MODULEPATH:
/Users/greghardy/.puppetlabs/bolt-code/modules:/Users/greghardy/.puppetlabs/bolt-code/site-modules:/Users/greghardy/.puppetlabs/etc/code/modules:/Users/greghardy/demo
```

## Configuration

There are a few ways to configure the number of instances that you require. Instances will be tagged with the role 
that you specify in the role schema. The roles.conf.example file illustrates how its possible to configure a conf file 
to pass to the provision plan.

```bash
$ cat roles.conf.example
[
  {"pe_master": 1},
  {"webserver": 3},
  {"mysql_servers": 2}
]
```

The same json above can be passed to the plan using the "roles" param. If you simply want a few nodes and dont want to tag them with roles
there is a simple parameter "num_nodes".

## Provisioning

With a roles config file

```bash
bundle exec bolt plan run puppet_bolt_aws::provision roles_file='roles.conf.example'
```

With roles specified via parameter

```bash
bundle exec bolt plan run puppet_bolt_aws::provision roles='[{"pe_master": 1},{"webserver": 3}]'
```

Or the basic num_nodes

```bash
bundle exec bolt plan run puppet_bolt_aws::provision num_nodes=4
```

If you are super lazy and just require a single instance.

```bash
bundle exec bolt plan run puppet_bolt_aws::provision
```

## Deprovisioning

```bash
bundle exec bolt plan run puppet_bolt_aws::deprovision
```

## Extra configuration

The tag will default to your '<username>-bolt'. This can be manually set with the 'tag' param. This tag will be used on every resource that
is created with the provision plan.

The inventory_file is where bolt stores the relevant information about instances that are created. If you want to set its location for any reason, use the 'inventory_file' parameter. You need only set the directory that the inventory file will reside in.

```bash
$ bundle exec bolt plan show puppet_bolt_aws::provision

puppet_bolt_aws::provision

USAGE:
bolt plan run puppet_bolt_aws::provision [num_nodes=<value>] [roles=<value>] [roles_file=<value>] [tag=<value>] [inventory_file=<value>]

PARAMETERS:
- num_nodes: Optional[Integer[1]]
- roles: Optional[String[1]]
- roles_file: Optional[String[1]]
- tag: Optional[String[1]]
- inventory_file: Optional[String[1]]

MODULE:
/Users/greghardy/demo/puppet_bolt_aws


```
