plan puppet_bolt_aws::provision(
  Optional[Integer[1]]   $num_nodes = undef,
  Optional[String[1]]    $roles = undef,
  Optional[String[1]]    $roles_file = undef,
  Optional[String[1]]    $tag = undef,
  Optional[String[1]]    $inventory_file = undef
) {
  info('running puppet_bolt_aws::provision_aws')

  if $tag == undef {
    $output_user = run_task('puppet_bolt_aws::facts', 'localhost', fact_name => 'id')
    $user = $output_user.first.value['_output']
    $basename = "${user}-bolt"
  }
  else {
    $basename = $tag
  }
  info("tag is ${basename}")

  if $inventory_file == undef {
    $output_home = run_task('puppet_bolt_aws::home_dir', 'localhost')
    $inv = $output_home.first.value['_output']
  }
  else {
    $inv = $inventory_file
  }
  info("tag is ${inv}")

  # Precidence of roles/file/num_nodes
  if $roles != undef {
    $roles_hash = $roles
    info("PARAM :: Roles=${$roles_hash}")
  }
  elsif $roles_file != undef {
    $roles_output = run_task('puppet_bolt_aws::read_roles', 'localhost', file => $roles_file)
    $roles_hash = $roles_output.first.value['_output']
    info("FILE :: Roles=${roles_hash}")
  }
  elsif $num_nodes != undef {
    $roles_hash = {'generic' => $num_nodes }
    info("NODES :: Roles=${roles_hash}")
  }
  else {
    $roles_hash = {'generic' => 1 }
    info("DEFAULT :: Roles=${roles_hash}")
  }

  $output_vpc = run_task('puppet_bolt_aws::create_vpc', 'localhost', tag_name => $basename)
  $vpc_id = $output_vpc.first.value['_output']
  info("vpc_id is ${vpc_id}")

  $output_sg = run_task('puppet_bolt_aws::create_security_group', 'localhost', group_name => $basename, vpc_id => $vpc_id)
  $sg_id = $output_sg.first.value['_output']
  info("sg_id is ${sg_id}")

  $output_sub = run_task('puppet_bolt_aws::create_subnet', 'localhost', tag_name => $basename, vpc_id => $vpc_id)
  $subnet_id = $output_sub.first.value['_output']
  info("subnet_id is ${subnet_id}")

  $output_ig = run_task('puppet_bolt_aws::create_internet_gateway', 'localhost', tag_name => $basename, vpc_id => $vpc_id)
  $ig_id = $output_ig.first.value['_output']
  info("ig_id is ${ig_id}")

  info("inventory file is ${inv}")

  $output_splunk = run_task('puppet_bolt_aws::create_instance', 'localhost', instance_name => $basename, subnet_id => $subnet_id, sg_id => $sg_id, inventory => $inv, roles => $roles_hash )  
  $splunk_master = $output_splunk.first.value['_output']
  info("instance id is ${splunk_master}")

  $output_table = run_task('puppet_bolt_aws::create_route', 'localhost', tag_name => $basename, vpc_id => $vpc_id, subnet_id => $subnet_id, ig_id => $ig_id)
  $table_id = $output_sub.first.value['_output']
  info("table_id is ${table_id}")

  info('puppet_bolt_aws::provision_aws complete')
}
