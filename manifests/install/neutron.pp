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
     $memcache_host = 'memcache',
     $controller_host = 'controller',
     $ostack_region       = 'RegionOne',
     $bstp_adm_port       = '35357',
     $bstp_int_port       = '5000',
     $bstp_pub_port       = '5000',
     $glance_adm_port       = '9292',
     $glance_int_port       = '9292',
     $glance_pub_port       = '9292',
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
                "OS_AUTH_URL=http://${controller_host}:${bstp_adm_port}/v3", 
                'OS_IDENTITY_API_VERSION=3', 
                ]

   # Pre requisites (user, endpoints, service, role)

   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   # File configuration
   # We only manage those which need modification
   file { 'neutron.conf':
      name    => '/etc/neutron/neutron.conf',
      ensure  => present,
      content => template('ostack_controller/neutron/neutron.conf.erb'),
      notify  => Exec['neutron-server-restart'],
   }
   file { 'linuxbridge_agent.ini':
      name    => '/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
      ensure  => present,
      content => template('ostack_controller/neutron/plugins/ml2/linuxbridge_agent.ini.erb'),
      notify  => Exec['neutron-linuxbridge-restart'],
   }
   file { 'ml2_conf.ini':
      name    => '/etc/neutron/plugins/ml2/ml2_conf.ini',
      ensure  => present,
      content => template('ostack_controller/neutron/plugins/ml2/ml2_conf.ini.erb'),
      notify  => Exec['neutron-linuxbridge-restart'],
   }
   file { 'dhcp_agent.ini':
      name    => '/etc/neutron/dhcp_agent.ini',
      ensure  => present,
      content => template('ostack_controller/neutron/dhcp_agent.ini.erb'),
      notify  => Exec['neutron-dhcp-restart'],
   }
   file { 'metadata_agent.ini':
      name    => '/etc/neutron/metadata_agent.ini',
      ensure  => present,
      content => template('ostack_controller/neutron/metadata_agent.ini.erb'),
      notify  => Exec['neutron-metadata-restart'],
   }
   file { 'l3_agent.ini':
      name    => '/etc/neutron/l3_agent.ini',
      ensure  => present,
      content => template('ostack_controller/neutron/l3_agent.ini.erb'),
      notify  => Exec['neutron-l3-restart'],
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
   } network service creation
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

   # Configure post install - populate DB
   exec { "neutron-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ File['neutron.conf'], File['ml2_conf.ini'], Package['neutron-server'], Package['neutron-plugin-ml2'], Package['neutron-linuxbridge-agent'], Package['neutron-l3-agent'], Package['neutron-dhcp-agent'], Package['neutron-metadata-agent'], ],
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
      command     => "su -s /bin/sh -c \"neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\" $dbname",
      timeout     => 600,
   }
   exec { "neutron-services-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Package['neutron-server'], Package['neutron-plugin-ml2'], Package['neutron-linuxbridge-agent'], Package['neutron-l3-agent'], Package['neutron-dhcp-agent'], Package['neutron-metadata-agent'], ],
      refreshonly => true,
      command     => 'service neutron-server restart && service neutron-linuxbridge-agent restart && service neutron-dhcp-agent restart && service neutron-metadata-agent restart && service neutron-l3-agent restart',
   }
   exec { "neutron-server-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => Package['neutron-server'], 
      refreshonly => true,
      command     => 'service neutron-server restart',
   }
   exec { "neutron-linuxbridge-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Package['neutron-server'], Package['neutron-linuxbridge-agent'], ],
      refreshonly => true,
      command     => 'service neutron-linuxbridge-agent restart',
   }
   exec { "neutron-dhcp-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Package['neutron-server'], Package['neutron-dhcp-agent'], ],
      refreshonly => true,
      command     => 'service neutron-dhcp-agent restart',
   }
   exec { "neutron-metadata-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Package['neutron-server'], Package['neutron-metadata-agent'], ],
      refreshonly => true,
      command     => 'service neutron-metadata-agent restart',
   }
   exec { "neutron-l3-restart":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => [ Package['neutron-server'], Package['neutron-l3-agent'], ],
      refreshonly => true,
      command     => 'service neutron-l3-agent restart',
   }
}
