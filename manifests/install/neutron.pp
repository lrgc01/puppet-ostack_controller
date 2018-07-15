# This should be ran only on the controller node
#
define ostack_controller::install::neutron (
     $dbtype  = 'mysql',
     $dbname  = 'neutron',
     $dbuser  = 'neutron',
     $dbpass  = 'neatomos3',
     $dbhost  = 'ostackdb',
     $neutronuser  = $dbuser,
     $neutronpass  = $dbpass,
     $glanceuser  = $dbuser,
     $glancepass  = $dbpass,
     $admindbpass = 'keatomos3',
     $metadatapass = 'meatomos3',
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
     $neutron_adm_port       = '9696',
     $neutron_int_port       = '9696',
     $neutron_pub_port       = '9696',
     $memcache_port = '11211',
     $service_descr = "OpenStack Networking",
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

   # Pre requisites (user, endpoints, service, role)

   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   # File configuration
   ostack_controller::files::neutron { 'install':
      dbtype   => $dbtype,
      dbname   => $dbname,
      dbuser   => $dbuser,
      dbpass   => $dbpass,
      dbhost   => $dbhost,
      neutronuser   => $neutronuser,
      neutronpass   => $neutronpass,
      admindbpass   => $admindbpass,
      metadatapass   => $metadatapass,
      memcache_host   => $memcache_host,
      controller_host   => $controller_host,
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
   }

   # Create keystone database
   ostack_controller::dbcreate { 'neutron':
     dbtype  => $dbtype,
     dbname  => $dbname,
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
     notify  => Exec['neutron-populate_db'],
   }

   # neutron user creation
   exec { 'NeutronUserCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack user create --domain default --password \"$neutronpass\" $neutronuser",
      unless      => "openstack user show $neutronuser",
      notify      => Exec['NeutronRoleAttribution'],
   }
   # admin role attribution
   exec { 'NeutronRoleAttribution':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      require     => Exec['NeutronUserCreation'],
      refreshonly => true,
      command     => "openstack role add --project service --user $neutronuser admin",
   } 
   # network service creation
   exec { 'NetworkServiceCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack service create --name $neutronuser --description \"$service_descr\" network",
      unless      => "openstack service show $neutronuser",
   }
   #
   # Endpoint creation
   # Note on 'unless': openstack command always returns 0 even if the endpoint 
   #                   is not found, that's why we use grep at the end.
   #
   exec { 'PubNetEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region network public http://$controller_host:$neutron_pub_port",
      unless      => "openstack endpoint list --region $ostack_region --interface public --service network|grep network",
   }
   exec { 'IntNetEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region network internal http://$controller_host:$neutron_int_port",
      unless      => "openstack endpoint list --region $ostack_region --interface internal --service network|grep network",
   }
   exec { 'AdmNetEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region network admin http://$controller_host:$neutron_adm_port",
      unless      => "openstack endpoint list --region $ostack_region --interface admin --service network|grep network",
   }

   # Makes sure neutron packages are installed
   package { 'neutron-server':
      ensure  => present,
   } 
   package { 'neutron-plugin-ml2':
      ensure  => present,
   } 
   package { 'neutron-linuxbridge-agent':
      ensure  => present,
   } 
   package { 'neutron-l3-agent':
      ensure  => present,
   } 
   package { 'neutron-dhcp-agent':
      ensure  => present,
   } 
   package { 'neutron-metadata-agent':
      ensure  => present,
   } 
   service { 'neutron-server':
      require => Package['neutron-server'],
      enable  => true,
   } 
   service { 'neutron-linuxbridge-agent':
      require => Package['neutron-linuxbridge-agent'],
      enable  => true,
   } 
   service { 'neutron-l3-agent':
      require => Package['neutron-l3-agent'],
      enable  => true,
   } 
   service { 'neutron-dhcp-agent':
      require => Package['neutron-dhcp-agent'],
      enable  => true,
   } 
   service { 'neutron-metadata-agent':
      require => Package['neutron-metadata-agent'],
      enable  => true,
   } 

   # Configure post install - populate DB
   exec { "neutron-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Ostack_controller::Files::Neutron['install'], Service['neutron-server'], Service['neutron-linuxbridge-agent'], Service['neutron-l3-agent'], Service['neutron-dhcp-agent'], Service['neutron-metadata-agent'], ],
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
      command     => "su -s /bin/sh -c \"neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\" $dbname",
      timeout     => 600,
   }
   exec { "neutron-services-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Service['neutron-server'], Service['neutron-linuxbridge-agent'], Service['neutron-l3-agent'], Service['neutron-dhcp-agent'], Service['neutron-metadata-agent'], ],
      refreshonly => true,
      command     => 'service neutron-server restart && service neutron-linuxbridge-agent restart && service neutron-dhcp-agent restart && service neutron-metadata-agent restart && service neutron-l3-agent restart',
   }
   exec { "neutron-server-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => Service['neutron-server'], 
      refreshonly => true,
      command     => 'service neutron-server restart',
   }
   exec { "neutron-linuxbridge-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Service['neutron-server'], Service['neutron-linuxbridge-agent'], ],
      refreshonly => true,
      command     => 'service neutron-linuxbridge-agent restart',
   }
   exec { "neutron-dhcp-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Service['neutron-server'], Service['neutron-dhcp-agent'], ],
      refreshonly => true,
      command     => 'service neutron-dhcp-agent restart',
   }
   exec { "neutron-metadata-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Service['neutron-server'], Service['neutron-metadata-agent'], ],
      refreshonly => true,
      command     => 'service neutron-metadata-agent restart',
   }
   exec { "neutron-l3-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Service['neutron-server'], Service['neutron-l3-agent'], ],
      refreshonly => true,
      command     => 'service neutron-l3-agent restart',
   }
}
