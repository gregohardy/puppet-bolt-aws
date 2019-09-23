plan puppet_bolt_aws::deprovision(
  Optional[String[1]] $tag = undef,
  Optional[String[1]] $inventory_file = undef
) {
  info('running puppet_bolt_aws::deprovision')

  if $tag == undef {
    $output_user = run_task('puppet_bolt_aws::facts', 'localhost', fact_name => 'id')
    $user = $output_user.first.value['_output']
    $basename = "${user}-bolt"
  }
  else {
    $basename = $tag
  }

  info("User is ${user}")

  if $inventory_file == undef {
    $output_home = run_task('puppet_bolt_aws::home_dir', 'localhost')
    $inv = $output_home.first.value['_output']
  }
  else {
    $inv = $inventory_file
  }
  info("Inventory is ${inv}")

  $output_vpc = run_task('puppet_bolt_aws::delete_aws', 'localhost', tag_name => $basename, inventory => $inv)
  $vpc_id = $output_vpc.first.value['_output']
  info("vpc_id is ${vpc_id}")

  info('puppet_bolt_aws::deprovision complete')
}
