# This should be ran only on the controller node
#
define ostack_controller::files::neutron (
     $dbtype  = 'mysql',
     $dbname  = 'neutron',
     $dbuser  = 'neutron',
     $dbpass  = 'neatomos3',
     $dbhost  = 'ostackdb',
     $neutronuser  = $neutrondbuser,
     $neutronpass  = $neutrondbpass,
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

   # Pre requisites (user, endpoints, service, role)
   # Will be used in templates
   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   # File configuration
   # We only manage those which need modification
   file { '/etc/neutron/plugins/ml2/':
      ensure  => directory,
   }
   file { 'neutron.conf':
      name    => '/etc/neutron/neutron.conf',
      ensure  => present,
      require => File['/etc/neutron/plugins/ml2/'],
      content => template('ostack_controller/neutron/neutron.conf.erb'),
   }
   file { 'linuxbridge_agent.ini':
      name    => '/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
      ensure  => present,
      require => File['/etc/neutron/plugins/ml2/'],
      content => template('ostack_controller/neutron/plugins/ml2/linuxbridge_agent.ini.erb'),
   }
   file { 'ml2_conf.ini':
      name    => '/etc/neutron/plugins/ml2/ml2_conf.ini',
      ensure  => present,
      require => File['/etc/neutron/plugins/ml2/'],
      content => template('ostack_controller/neutron/plugins/ml2/ml2_conf.ini.erb'),
   }
   file { 'dhcp_agent.ini':
      name    => '/etc/neutron/dhcp_agent.ini',
      ensure  => present,
      require => File['/etc/neutron/plugins/ml2/'],
      content => template('ostack_controller/neutron/dhcp_agent.ini.erb'),
   }
   file { 'metadata_agent.ini':
      name    => '/etc/neutron/metadata_agent.ini',
      ensure  => present,
      require => File['/etc/neutron/plugins/ml2/'],
      content => template('ostack_controller/neutron/metadata_agent.ini.erb'),
   }
   file { 'l3_agent.ini':
      name    => '/etc/neutron/l3_agent.ini',
      ensure  => present,
      require => File['/etc/neutron/plugins/ml2/'],
      content => template('ostack_controller/neutron/l3_agent.ini.erb'),
   }

}
