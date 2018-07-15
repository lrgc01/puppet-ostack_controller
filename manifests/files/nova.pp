# This should be ran only on the controller node
#
define ostack_controller::files::nova (
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

   # Pre requisites (user, endpoints, service, role)
   # Will be used in templates
   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   # File configuration
   # We only manage those which need modification
   file { '/etc/nova':
      ensure => directory,
   }
   file { 'nova.conf':
      name    => '/etc/nova/nova.conf',
      ensure  => present,
      require => File['/etc/nova'],
      content => template('ostack_controller/nova/nova.conf.erb'),
   }

}
