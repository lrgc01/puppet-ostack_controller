# This should be ran only on the controller node
#
define ostack_controller::install::neutron (
     $dbtype           = 'mysql',
     $dbname           = 'neutron',
     $dbuser           = 'neutron',
     $dbpass           = 'neatomos3',
     $dbhost           = 'ostackdb',
     $neutronuser      = $dbuser,
     $neutronpass      = $dbpass,
     $glanceuser       = $dbuser,
     $glancepass       = $dbpass,
     $novauser         = 'nova',
     $novapass         = 'noatomos3',
     $admindbpass      = 'keatomos3',
     $metadatapass     = 'meatomos3',
     $memcache_host    = 'memcache',
     $controller_host  = 'controller',
     $mq_proto         = 'rabbit',
     $mq_user          = 'openstack',
     $mq_pass          = 'raatomos3',
     $mq_host          = 'rabbitmq',
     $ostack_region    = 'RegionOne',
     $bstp_adm_port    = '35357/v3/',
     $bstp_int_port    = '5000/v3/',
     $bstp_pub_port    = '5000/v3/',
     $nova_adm_port    = '8774/v2.1',
     $nova_int_port    = '8774/v2.1',
     $nova_pub_port    = '8774/v2.1',
     $placem_adm_port  = '8778',
     $placem_int_port  = '8778',
     $placem_pub_port  = '8778',
     $glance_adm_port  = '9292',
     $glance_int_port  = '9292',
     $glance_pub_port  = '9292',
     $neutron_adm_port = '9696',
     $neutron_int_port = '9696',
     $neutron_pub_port = '9696',
     $memcache_port    = '11211',
     $service_descr    = "OpenStack Networking",
) {

   $path          = { path   => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'] }

   $env           = ['HOME=/root','USER=root']

   $admin_env     = $env + [
                    'OS_USERNAME=admin',
                    "OS_PASSWORD=$admindbpass",
                    'OS_PROJECT_NAME=admin',
                    'OS_USER_DOMAIN_NAME=Default',
                    'OS_PROJECT_DOMAIN_NAME=Default',
                    "OS_AUTH_URL=http://${controller_host}:${bstp_adm_port}",
                    'OS_IDENTITY_API_VERSION=3',
                    ]
   $exec_attr_hash = $path + { environment => $admin_env }

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
      *           => $exec_attr_hash,
      command     => "openstack user create --domain default --password \"$neutronpass\" $neutronuser",
      unless      => "openstack user show $neutronuser",
      notify      => Exec['NeutronRoleAttribution'],
   }
   # admin role attribution
   exec { 'NeutronRoleAttribution':
      *           => $exec_attr_hash,
      require     => Exec['NeutronUserCreation'],
      refreshonly => true,
      command     => "openstack role add --project service --user $neutronuser admin",
   } 
   # network service creation
   exec { 'NetworkServiceCreation':
      *           => $exec_attr_hash,
      command     => "openstack service create --name $neutronuser --description \"$service_descr\" network",
      unless      => "openstack service show $neutronuser",
   }
   #
   # Endpoint creation
   # Note on 'unless': openstack command always returns 0 even if the endpoint 
   #                   is not found, that's why we use grep at the end.
   #
   exec { 'PubNetEndpointCreation':
      *           => $exec_attr_hash,
      command     => "openstack endpoint create --region $ostack_region network public http://$controller_host:$neutron_pub_port",
      unless      => "openstack endpoint list --region $ostack_region --interface public --service network|grep network",
   }
   exec { 'IntNetEndpointCreation':
      *           => $exec_attr_hash,
      command     => "openstack endpoint create --region $ostack_region network internal http://$controller_host:$neutron_int_port",
      unless      => "openstack endpoint list --region $ostack_region --interface internal --service network|grep network",
   }
   exec { 'AdmNetEndpointCreation':
      *           => $exec_attr_hash,
      command     => "openstack endpoint create --region $ostack_region network admin http://$controller_host:$neutron_adm_port",
      unless      => "openstack endpoint list --region $ostack_region --interface admin --service network|grep network",
   }

   $base_pak = [ 'neutron-server', 'neutron-linuxbridge-agent', 'neutron-l3-agent', 'neutron-dhcp-agent', 'neutron-metadata-agent', ]
   $packages = [ $base_pak ] + [ 'neutron-plugin-ml2', ]
   $services = [ $base_pak ] + [ 'neutron-linuxbridge-cleanup', ]
   $services_list = "neutron-server neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent neutron-linuxbridge-cleanup"

   # Make sure neutron packages are installed
   package { $packages:
      ensure  => present,
   } 
   service { $services:
      require => Package[$packages],
      enable  => true,
      ensure  => 'running',
   } 

    $most_required = [ Ostack_controller::Files::Neutron['install'], 
		       Service[$services],
		     ]
   # Configure post install - populate DB
   exec { "neutron-populate_db":
      *           => $exec_attr_hash,
      require     => $most_required,
      refreshonly => true,
      onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
      command     => "su -s /bin/sh -c \"neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\" $dbname",
      timeout     => 600,
      notify      => Exec['restart-neutron'],
   }

   exec { 'restart-neutron':
      *           => $exec_attr_hash,
      require     => Package[$packages],
      subscribe   => Exec['neutron-populate_db'],
      refreshonly => true,
      command     => "systemctl restart $services_list",
   } 
}
