# This should be ran only on the controller node
#
define ostack_controller::files::glance (
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

   # Pre requisites (user, endpoints, service, role)
   # Will be used in templates
   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   # File configuration
   # We only manage those which need modification
   file { '/etc/glance':
      ensure  => directory,
   }
   file { 'glance-api.conf':
      name    => '/etc/glance/glance-api.conf',
      ensure  => present,
      require => File['/etc/glance'],
      content => template('ostack_controller/glance/glance-api.conf.erb'),
   }
   file { 'glance-registry.conf':
      name    => '/etc/glance/glance-registry.conf',
      ensure  => present,
      require => File['/etc/glance'],
      content => template('ostack_controller/glance/glance-registry.conf.erb'),
   }

}
