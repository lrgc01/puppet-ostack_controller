# This should be ran only on the controller node
#
define ostack_controller::install::keystone (
     $dbtype  = 'mysql',
     $dbname  = 'keystone',
     $dbuser  = 'keystone',
     $dbpass  = 'keatomos3',
     $dbhost  = 'ostackdb',
     $controller_host = 'controller',
     $ostack_region       = 'RegionOne',
     $bstp_adm_port       = '35357/v3/',
     $bstp_int_port       = '5000/v3/',
     $bstp_pub_port       = '5000/v3/',
     $service_proj_descr = "Service Project",
     $demo_create     = true,
     $demo_prj_name   = 'demo',
     $demo_proj_descr = "Demo Project",
     $demo_user       = 'demo',
     $demo_pass	      = 'demopass',
) {

   # Set shell environment
   $admin_env = ['HOME=/root','USER=root',
		 'OS_USERNAME=admin',
		 "OS_PASSWORD=$dbpass",
		 'OS_PROJECT_NAME=admin',
		 'OS_USER_DOMAIN_NAME=Default',
		 'OS_PROJECT_DOMAIN_NAME=Default',
		 "OS_AUTH_URL=http://${controller_host}:${bstp_adm_port}", 
		 'OS_IDENTITY_API_VERSION=3',
		 ]

   $packages = [ 'keystone', 'apache2', 'libapache2-mod-wsgi', ],
   # Makes sure keystone, apache2 and libapache2-mod-wsgi are installed
   package { $packages:
      ensure  => present,
   }
   ostack_controller::service::keystone { 'install':
      enable  => true,
      ensure  => 'running',
      require => Package[$packages],
      before  => Exec["keystone-populate_db"],
   }

   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   ostack_controller::files::keystone { 'install':
      dbtype  => $dbtype,
      dbname => $dbname,
      dbuser => $dbuser,
      dbpass => $dbpass,
      dbhost => $dbhost,
      controller_host  => $controller_host,
      ostack_region    => $ostack_region,
      bstp_adm_port    => $bstp_int_port,
      bstp_int_port    => $bstp_int_port,
      bstp_pub_port    => $bstp_pub_port,
      service_proj_descr => $service_proj_descr,
      notify  => Exec['fernet_setup'],
   }

   # Create keystone database
   ostack_controller::dbcreate { 'keystone':
     dbtype  => $dbtype,
     dbname  => $dbname,
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
     notify  => Exec['keystone-populate_db'],
   }

   $most_required = [ Ostack_controller::Files::Keystone['install'],
                      Exec['keystone-populate_db'],
                    ],

   $most_required2 = [ Ostack_controller::Files::Keystone['install'], 
		       Exec['keystone-populate_db'], 
		       Exec['credential_setup'], 
		       Exec['keystone-bootstrap'], 
		     ],

   # Configure post install - populate DB, initialize repositories, bootstrap service
   exec { "keystone-populate_db":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      subscribe   => [ Ostack_controller::Files::Keystone['install'], 
                       Ostack_controller::Dbcreate['keystone'], 
		     ],
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
      command     => "su -s /bin/sh -c \"keystone-manage db_sync\" $dbname",
      timeout     => 600,
      notify      => Exec["keystone-bootstrap"],
   }
   exec { 'fernet_setup':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => $most_required,
      onlyif      => "test ! -f /etc/keystone/fernet-keys/0 -o ! -f /etc/keystone/fernet-keys/1",
      command     => "keystone-manage fernet_setup --keystone-user $dbuser --keystone-group $dbuser",
   }
   exec { 'credential_setup':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      require     => $most_required,
      onlyif      => "test ! -f /etc/keystone/credential-keys/0 -o ! -f /etc/keystone/credential-keys/1",
      command     => "keystone-manage credential_setup --keystone-user $dbuser --keystone-group $dbuser",
   }
   exec { "keystone-bootstrap":
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      subscribe   => $most_required,
      refreshonly => true,
      command     => "keystone-manage bootstrap --bootstrap-password $dbpass --bootstrap-admin-url http://$controller_host:$bstp_adm_port --bootstrap-internal-url http://$controller_host:$bstp_int_port --bootstrap-public-url http://$controller_host:$bstp_pub_port --bootstrap-region-id $ostack_region",
      notify      => Exec['ServiceProjectCreation'],
   }
   # Base mandatory service project creation
   exec { 'ServiceProjectCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      require     => $most_required2,
      command     => "openstack project create --domain default --description \"$service_proj_descr\" service",
      unless      => "openstack project show service",
   }
   # Base user role 
   exec { 'UserRoleCreation':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => $admin_env,
      require     => $most_required2,
      command     => "openstack role create user",
      unless      => "openstack role show user",
   }
   # Optional 'Demo' project creation
   if $demo_create {
      exec { 'DemoProjectCreation':
         path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
         environment => $admin_env,
         require     => $most_required2,
         command     => "openstack project create --domain default --description \"$demo_proj_descr\" $demo_prj_name",
         unless      => "openstack project show $demo_prj_name",
	 notify      => Exec['DemoRoleAttribution'],
      }
      exec { 'DemoUserCreation':
         path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
         environment => $admin_env,
         require     => $most_required2,
         command     => "openstack user create --domain default --password \"$demo_pass\" $demo_user",
         unless      => "openstack user show $demo_user",
      }
      exec { 'DemoRoleAttribution':
         path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
         environment => $admin_env,
         subscribe   => [ Exec['UserRoleCreation'], 
	 		  Exec['DemoUserCreation'], 
			],
	 refreshonly => true,
         command     => "openstack role add --project $demo_prj_name --user $demo_user user",
      }
   }
}
