# This should be ran only on the controller node
#
define ostack_controller::files::keystone (
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
) {

   # Will be used in templates
   if "$dbtype" == 'mysql' {
      $dbconnection = "mysql+pymysql"
   }

   # File configuration
   # for now, only manage those which need modification
   file { '/etc/keystone':
      ensure  => directory,
   }
   file { 'keystone.conf':
      name    => '/etc/keystone/keystone.conf',
      ensure  => present,
      require => File['/etc/keystone'],
      content => template('ostack_controller/keystone/keystone.conf.erb'),
   }
   file { 'apache2.conf':
      name    => '/etc/apache2/apache2.conf',
      ensure  => present,
      require => File['/etc/keystone'],
      content => template('ostack_controller/apache2/apache2.conf.erb'),
   }
}
