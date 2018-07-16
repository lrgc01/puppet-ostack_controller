# This should be ran only on the controller node
#
define ostack_controller::install::glance (
     $dbtype  = 'mysql',
     $dbname  = 'glance',
     $dbuser  = 'glance',
     $dbpass  = 'glatomos3',
     $dbhost  = 'ostackdb',
     $glanceuser  = $dbuser,
     $glancepass  = $dbpass,
     $admindbpass = 'keatomos3',
     $memcache_host = 'memcache',
     $controller_host = 'controller',
     $ostack_region       = 'RegionOne',
     $bstp_adm_port       = '35357/v3/',
     $bstp_int_port       = '5000/v3/',
     $bstp_pub_port       = '5000/v3/',
     $glance_adm_port       = '9292',
     $glance_int_port       = '9292',
     $glance_pub_port       = '9292',
     $memcache_port = '11211',
     $service_descr = "OpenStack Image",
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

   $services = [ 'glance-api', 'glance-registry' ]
   # Make sure glance package is installed
   package { $services:
      ensure  => present,
   }
   ostack_controller::files::glance { 'install':
      dbtype  => $dbtype,
      dbname  => $dbname,
      dbuser  => $dbuser,
      dbpass  => $dbpass,
      dbhost  => $dbhost,
      glanceuser    => $glanceuser,
      glancepass    => $glancepass,
      admindbpass   => $admindbpass,
      memcache_host    => $memcache_host,
      controller_host  => $controller_host,
      ostack_region    => $ostack_region,
      bstp_adm_port    => $bstp_adm_port,
      bstp_int_port    => $bstp_int_port,
      bstp_pub_port    => $bstp_pub_port,
      glance_adm_port  => $glance_adm_port,
      glance_int_port  => $glance_int_port,
      glance_pub_port  => $glance_pub_port,
      memcache_port    => $memcache_port,
      service_descr => $service_descr,
      require       => Package[$services],
   }

   ostack_controller::services::glance { 'install':
      enable  => true,
      ensure  => 'running',
      require => [ Package[$services], 
                   Ostack_controller::Files::Glance['install'], 
                 ],
      before  => Exec['glance-populate_db'],
   }


   # Create glance database
   ostack_controller::dbcreate { 'glance':
     dbtype  => $dbtype,
     dbname  => $dbname,
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
     notify  => Exec['glance-populate_db'],
   }

   # Configure post install - populate DB
   exec { "glance-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      subscribe   => [ Ostack_controller::Files::Glance['install'], 
                       Package['glance-api'], 
                       Package['glance-registry'],
                     ],
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
      command     => "su -s /bin/sh -c \"glance-manage db_sync\" $dbname",
      timeout     => 600,
   }

   # After here everything occurs in identity service
   exec { 'GlanceUserCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack user create --domain default --password \"$glancepass\" $glanceuser",
      unless      => "openstack user show $glanceuser",
      notify      => Exec['GlanceRoleAttribution'],
   }
   # admin role attribution
   exec { 'GlanceRoleAttribution':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      subscribe   => Exec['GlanceUserCreation'],
      refreshonly => true,
      command     => "openstack role add --project service --user $glanceuser admin",
   }
   exec { 'ImageServiceCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack service create --name $glanceuser --description \"$service_descr\" image",
      unless      => "openstack service show $glanceuser",
   }
   #
   # Endpoint creation
   # Note on 'unless': openstack command always returns 0 even if the endpoint 
   #                   is not found, that's why we use grep at the end.
   #
   exec { 'PubImageEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region image public http://$controller_host:$glance_pub_port",
      unless      => "openstack endpoint list --region $ostack_region --interface public --service image|grep image",
   }
   exec { 'IntImageEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region image internal http://$controller_host:$glance_int_port",
      unless      => "openstack endpoint list --region $ostack_region --interface internal --service image|grep image",
   }
   exec { 'AdmImageEndpointCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      command     => "openstack endpoint create --region $ostack_region image admin http://$controller_host:$glance_adm_port",
      unless      => "openstack endpoint list --region $ostack_region --interface admin --service image|grep image",
   }
}
