# This should be ran only on the controller node
#
define ostack_controller::install::nova (
     $dbtype  = 'mysql',
     $dbname  = 'nova',
     $apidbname  = 'nova_api',
     $dbuser  = 'nova',
     $dbpass  = 'noatomos3',
     $dbhost  = 'ostackdb',
     $novauser  = $dbuser,
     $novapass  = $dbpass,
     $placemuser  = 'placement',
     $placempass  = 'platomos3',
     $admindbpass = 'keatomos3',
     $memcache_host = 'memcache',
     $controller_host = 'controller',
     $mq_proto = 'rabbit',
     $mq_user  = 'openstack',
     $mq_pass  = 'raatomos3',
     $mq_host  = 'rabbitmq',
     $ostack_region       = 'RegionOne',
     $bstp_adm_port       = '35357/v3/',
     $bstp_int_port       = '5000/v3/',
     $bstp_pub_port       = '5000/v3/',
     $nova_adm_port       = '8774/v2.1',
     $nova_int_port       = '8774/v2.1',
     $nova_pub_port       = '8774/v2.1',
     $placem_adm_port     = '8778',
     $placem_int_port     = '8778',
     $placem_pub_port     = '8778',
     $glance_adm_port     = '9292',
     $glance_int_port     = '9292',
     $glance_pub_port     = '9292',
     $memcache_port       = '11211',
     $service_descr = "OpenStack Compute",
     $placem_service_descr = "Placement API",
) {

   # Set shell environment
   $admin_env = ['HOME=/root','USER=root', 
                'OS_USERNAME=admin', 
                "OS_PASSWORD=$admindbpass", 
                'OS_PROJECT_NAME=admin', 
                'OS_USER_DOMAIN_NAME=Default', 
                'OS_PROJECT_DOMAIN_NAME=Default', 
                "OS_AUTH_URL=http://${controller_host}:${bstp_adm_port}", 
                'OS_IDENTITY_API_VERSION=3', 
                ]

   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   ######
   # Nova uses 3 databases: nova_api, nova, nova_cell0
   # Create nova_api database
   ostack_controller::dbcreate { 'nova_api':
     dbtype  => $dbtype,
     dbname  => 'nova_api',
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
     notify  => Exec['nova_api-populate_db'],
   }
   # Create nova database
   ostack_controller::dbcreate { 'nova':
     dbtype  => $dbtype,
     dbname  => 'nova',
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
     notify  => Exec['nova-populate_db'],
   }
   # Create nova_cell0 database
   ostack_controller::dbcreate { 'nova_cell0':
     dbtype  => $dbtype,
     dbname  => 'nova_cell0',
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }

   # Pre requisites (user, endpoints, service, role)

   #######
   # Nova user creation, role attribution, service creation:
   #
   exec { 'NovaUserCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack user create --domain default --password \"$novapass\" $novauser",
      unless      => "openstack user show $novauser",
      notify      => Exec['NovaRoleAttribution'],
   }
   # admin role attribution
   exec { 'NovaRoleAttribution':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      require     => Exec['NovaUserCreation'],
      refreshonly => true,
      command     => "openstack role add --project service --user $novauser admin",
   }
   # compute service named $novauser (which is normally 'nova')
   exec { 'NovaServiceCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack service create --name $novauser --description \"$service_descr\" compute",
      unless      => "openstack service show $novauser",
   }
   ######
   # Now same for placement: user, role, service
   # Placement user with $placempass
   exec { 'PlacementUserCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack user create --domain default --password \"$placempass\" $placemuser",
      unless      => "openstack user show $placemuser",
      notify      => Exec['PlacementRoleAttribution'],
   }
   # admin role attribution
   exec { 'PlacementRoleAttribution':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      require     => Exec['PlacementUserCreation'],
      refreshonly => true,
      command     => "openstack role add --project service --user $placemuser admin",
   }
   # placement service named $placemuser (which is normally 'placement')
   exec { 'PlacementServiceCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack service create --name $placemuser --description \"$placem_service_descr\" placement",
      unless      => "openstack service show $placemuser",
   }
   ######

   # Endpoint creation
   # Note on 'unless': openstack command always returns 0 even if the endpoint 
   #                   is not found, that's why we use grep at the end.
   #
   # For nova compute, i.e. the compute service named 'nova':
   exec { 'PubComputeEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region compute public http://$controller_host:$nova_pub_port",
      unless      => "openstack endpoint list --region $ostack_region --interface public --service compute|grep compute",
   }
   exec { 'IntComputeEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region compute internal http://$controller_host:$nova_int_port",
      unless      => "openstack endpoint list --region $ostack_region --interface internal --service compute|grep compute",
   }
   exec { 'AdmComputeEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region compute admin http://$controller_host:$nova_adm_port",
      unless      => "openstack endpoint list --region $ostack_region --interface admin --service compute|grep compute",
   }
   #
   # The same for placement endpoints
   # For placement api, i.e. the placement service which is normally named 'placement':
   exec { 'PubPlacementEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region placement public http://$controller_host:$placem_pub_port",
      unless      => "openstack endpoint list --region $ostack_region --interface public --service placement|grep placement",
   }
   exec { 'IntPlacementEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region placement internal http://$controller_host:$placem_int_port",
      unless      => "openstack endpoint list --region $ostack_region --interface internal --service placement|grep placement",
   }
   exec { 'AdmPlacementEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region placement admin http://$controller_host:$placem_adm_port",
      unless      => "openstack endpoint list --region $ostack_region --interface admin --service placement|grep placement",
   }

   ######
   # Makes sure nova packages are installed:
   #   nova-api nova-conductor nova-consoleauth 
   #   nova-novncproxy nova-scheduler nova-placement-api
   package { 'nova-api':
      ensure  => present,
   }
   package { 'nova-conductor':
      ensure  => present,
   }
   package { 'nova-consoleauth':
      ensure  => present,
   }
   package { 'nova-novncproxy':
      ensure  => present,
   }
   package { 'nova-scheduler':
      ensure  => present,
   }
   package { 'nova-placement-api':
      ensure  => present,
   }
   exec { "nova-service-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Package['nova-api'], Package['nova-conductor'], Package['nova-consoleauth'], Package['nova-novncproxy'], Package['nova-scheduler'], Package['nova-placement-api'], ],
      refreshonly => true,
      command     => 'service nova-api restart && service nova-consoleauth restart && service nova-scheduler restart && service nova-conductor restart && service nova-novncproxy restart',
   }

   # File configuration
   # We only manage those which need modification
   file { 'nova.conf':
      name    => '/etc/nova/nova.conf',
      ensure  => present,
      content => template('ostack_controller/nova/nova.conf.erb'),
      notify  => Exec['nova-service-restart'],
   }

   ######
   # Nova uses 3 databases: nova_api, nova, nova_cell0
   # Pupulate the three and create cell1
   # Configure post install - populate nova-api DB
   exec { "nova_api-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ File['nova.conf'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w nova_api)` = x\"nova_api\"",
      command     => "su -s /bin/sh -c \"nova-manage api_db sync\" $novauser",
      timeout     => 600,
   }
   # Configure post install - register cell0 DB (in nova_cell0 DB)
   exec { "nova_cell0-register_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ File['nova.conf'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w nova_cell0)` = x\"nova_cell0\"",
      unless      => 'nova-manage cell_v2 list_cells |grep -w cell0',
      command     => "su -s /bin/sh -c \"nova-manage cell_v2 map_cell0\" $novauser",
   }
   # Configure post install - create nova cell1 cell
   exec { "nova-cell1-create":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ File['nova.conf'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w nova_cell0)` = x\"nova_cell0\"",
      unless      => 'nova-manage cell_v2 list_cells |grep -w cell1',
      command     => "su -s /bin/sh -c \"nova-manage cell_v2 create_cell --name=cell1\" $novauser",
   }
   # Configure post install - populate nova DB
   exec { "nova-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ File['nova.conf'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
      command     => "su -s /bin/sh -c \"nova-manage db sync\" $novauser",
      timeout     => 600,
   }
   #######
}
