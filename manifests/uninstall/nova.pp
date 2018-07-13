# This should be ran only on the controller node
#
define ostack_controller::uninstall::nova (
     $dbtype  = 'mysql',
     $dbname  = 'nova',
     $dbuser  = 'nova',
     $dbpass  = 'noatomos3',
     $dbhost  = 'ostackdb',
) {

   service { 'nova-consoleauth':
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   service { 'nova-novncproxy':
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   service { 'nova-placement-api':
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   service { 'nova-scheduler':
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   service { 'nova-conductor':
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   service { 'nova-api':
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }

   ostack_controller::dropdb { 'nova_api':
     dbtype  => $dbtype,
     dbname  => 'nova_api',
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }
   # Create nova database
   ostack_controller::dropdb { 'nova':
     dbtype  => $dbtype,
     dbname  => 'nova',
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }
   # Create nova_cell0 database
   ostack_controller::dropdb { 'nova_cell0':
     dbtype  => $dbtype,
     dbname  => 'nova_cell0',
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }

   ######
   # Make sure nova packages are uninstalled:
   #   nova-api nova-conductor nova-consoleauth 
   #   nova-novncproxy nova-scheduler nova-placement-api
   package { 'nova-api-uninstall':
      name   => 'nova-api',
      ensure => absent,
      require => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   package { 'nova-conductor-uninstall':
      name   => 'nova-conductor',
      ensure => absent,
      require => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   package { 'nova-consoleauth-uninstall':
      name   => 'nova-consoleauth',
      ensure => absent,
      require => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   package { 'nova-novncproxy-uninstall':
      name   => 'nova-novncproxy',
      ensure => absent,
      require => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   package { 'nova-scheduler-uninstall':
      name   => 'nova-scheduler',
      ensure => absent,
      require => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }
   package { 'nova-placement-api-uninstall':
      name   => 'nova-placement-api',
      ensure => absent,
      require => [ Ostack_controller::Dropdb['nova_api'], Ostack_controller::Dropdb['nova'], Ostack_controller::Dropdb['nova_cell0'], ],
   }

}
