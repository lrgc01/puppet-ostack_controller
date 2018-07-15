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
     $neutronuser  = 'neutron',
     $neutronpass  = 'neatomos3',
     $admindbpass = 'keatomos3',
     $memcache_host = 'memcache',
     $metadatapass = 'meatomos3',
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
     $neutron_adm_port    = '9696',
     $neutron_int_port    = '9696',
     $neutron_pub_port    = '9696',
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
     notify  => [ Exec['nova_cell0-register_db'], Exec['nova-cell1-create'], ],
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
   # Makes sure nova packages are installed and enabled (after a uninstall may be disabled):
   #   nova-api nova-conductor nova-consoleauth 
   #   nova-novncproxy nova-scheduler nova-placement-api
   # Note: There is no service "nova-placement-api". It uses WSGI on apache2.
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
   service { 'nova-api':
      require => Package['nova-api'],
      enable  => true,
   }
   service { 'nova-conductor':
      require => Package['nova-conductor'],
      enable  => true,
   }
   service { 'nova-consoleauth':
      require => Package['nova-consoleauth'],
      enable  => true,
   }
   service { 'nova-novncproxy':
      require => Package['nova-novncproxy'],
      enable  => true,
   }
   service { 'nova-scheduler':
      require => Package['nova-scheduler'],
      enable  => true,
   }
   exec { "nova-services-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Service['nova-api'], Service['nova-conductor'], Service['nova-consoleauth'], Service['nova-novncproxy'], Service['nova-scheduler'], ],
      refreshonly => true,
      command     => 'service nova-api restart && service nova-consoleauth restart && service nova-scheduler restart && service nova-conductor restart && service nova-novncproxy restart',
   }

   ostack_controller::files::nova { 'install': 
      dbtype  => $dbtype,
      dbname    => $dbname,
      apidbname => $apidbname,
      dbuser    => $dbuser,
      dbpass    => $dbpass,
      dbhost    => $dbhost,
      novauser  => $novauser,
      novapass  => $novapass,
      placemuser  => $placemuser,
      placempass  => $placempass,
      neutronuser  => $neutronuser,
      neutronpass  => $neutronpass,
      admindbpass  => $admindbpass,
      memcache_host  => $memcache_host,
      metadatapass  => $metadatapass,
      controller_host  => $controller_host,
      mq_proto   => $mq_proto,
      mq_user   => $mq_user,
      mq_pass   => $mq_pass,
      mq_host   => $mq_host,
      ostack_region   => $ostack_region,
      bstp_adm_port   => $bstp_adm_port,
      bstp_int_port   => $bstp_int_port,
      bstp_pub_port   => $bstp_pub_port,
      nova_adm_port   => $nova_adm_port,
      nova_int_port   => $nova_int_port,
      nova_pub_port   => $nova_pub_port,
      placem_adm_port   => $placem_adm_port,
      placem_int_port   => $placem_int_port,
      placem_pub_port   => $placem_pub_port,
      glance_adm_port   => $glance_adm_port,
      glance_int_port   => $glance_int_port,
      glance_pub_port   => $glance_pub_port,
      neutron_adm_port   => $neutron_adm_port,
      neutron_int_port   => $neutron_int_port,
      neutron_pub_port   => $neutron_pub_port,
      memcache_port   => $memcache_port,
      service_descr   => $service_descr,
      placem_service_descr   => $placem_service_descr,
      notify  => Exec['nova-services-restart'],
   }
   # File configuration
   # We only manage those which need modification
#   file { 'nova.conf':
#      name    => '/etc/nova/nova.conf',
#      ensure  => present,
#      content => template('ostack_controller/nova/nova.conf.erb'),
#      notify  => Exec['nova-services-restart'],
#   }

   ######
   # Nova uses 3 databases: nova_api, nova, nova_cell0
   # Pupulate the three and create cell1
   # Configure post install - populate nova-api DB
   exec { "nova_api-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Ostack_controller::Files::Nova['install'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      refreshonly => true,
      before      => [ Exec['nova_cell0-register_db'], Exec['nova-cell1-create'], Exec['nova-populate_db'], ],
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w nova_api)` = x\"nova_api\"",
      command     => "su -s /bin/sh -c \"nova-manage api_db sync\" $novauser",
      timeout     => 600,
   }
   # Configure post install - register cell0 DB (in nova_cell0 DB)
   exec { "nova_cell0-register_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Ostack_controller::Files::Nova['install'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      refreshonly => true,
      before      => [ Exec['nova-cell1-create'], Exec['nova-populate_db'], ],
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w nova_cell0)` = x\"nova_cell0\"",
      command     => "su -s /bin/sh -c \"nova-manage cell_v2 map_cell0\" $novauser",
   }
   # Configure post install - create nova cell1 cell
   exec { "nova-cell1-create":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Ostack_controller::Files::Nova['install'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      refreshonly => true,
      before      => Exec['nova-populate_db'],
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w nova_cell0)` = x\"nova_cell0\"",
      command     => "su -s /bin/sh -c \"nova-manage cell_v2 create_cell --name=cell1\" $novauser",
   }
   # Configure post install - populate nova DB
   exec { "nova-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Ostack_controller::Files::Nova['install'], Package['nova-api'], Package['nova-conductor'], Package['nova-scheduler'], Ostack_controller::Dbcreate[nova_api], Ostack_controller::Dbcreate[nova_cell0], Ostack_controller::Dbcreate[nova],],
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
      command     => "su -s /bin/sh -c \"nova-manage db sync\" $novauser",
      timeout     => 600,
   }
   #######
}
