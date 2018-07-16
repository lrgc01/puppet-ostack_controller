# This should be ran only on the controller node
#
define ostack_controller::uninstall::glance (
     $dbtype  = 'mysql',
     $dbname  = 'glance',
     $dbuser  = 'glance',
     $dbpass  = 'glatomos3',
     $dbhost  = 'ostackdb',
) {

   $services = [ 'glance-api', 'glance-registry' ]

   ostack_controller::services::glance { 'uninstall':
     ensure  => stopped,
     enable  => false,
     before  => [ Ostack_controller::Dropdb['glance'],
		  Package[$services],
	        ],
   }

   # Drop glance database
   ostack_controller::dropdb { 'glance':
     dbtype  => $dbtype,
     dbname  => $dbname,
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }

   # Make sure glance package is installed
   package { $services:
      ensure  => absent,
   }

}
