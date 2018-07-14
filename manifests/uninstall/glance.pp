# This should be ran only on the controller node
#
define ostack_controller::uninstall::glance (
     $dbtype  = 'mysql',
     $dbname  = 'glance',
     $dbuser  = 'glance',
     $dbpass  = 'glatomos3',
     $dbhost  = 'ostackdb',
) {
   service { "glance-registry-stop":
      name   => 'glance-registry',
      ensure => stopped,
      before => [ Service['glance-api-stop'], Ostack_controller::Dropdb['glance'],],
   }
   service { "glance-api-stop":
      name   => 'glance-api',
      ensure => stopped,
      before => Ostack_controller::Dropdb['glance'],
   }

   # Drop glance database
   ostack_controller::dropdb { 'glance':
     dbtype  => $dbtype,
     dbname  => $dbname,
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }

   # Make sure glance package is uninstalled
   package { 'glance-api-uninstall':
      name   => 'glance-api',
      ensure => absent,
      require  => Ostack_controller::Dropdb['glance'],
   }
   package { 'glance-registry-uninstall':
      name   => 'glance-registry',
      ensure => absent,
      require  => Ostack_controller::Dropdb['glance'],
   }
}
