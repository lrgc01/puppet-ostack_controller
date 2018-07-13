# This should be ran only on the controller node
#
define ostack_controller::uninstall::neutron (
     $dbtype  = 'mysql',
     $dbname  = 'neutron',
     $dbuser  = 'neutron',
     $dbpass  = 'neatomos3',
     $dbhost  = 'ostackdb',
) {

   service { "neutron-linuxbridge-agent":
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['neutron'], Service['neutron-server-stop'], ],
   }
   service { "neutron-linuxbridge-cleanup":
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['neutron'], Service['neutron-server-stop'], ],
   }
   service { "neutron-dhcp-agent":
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['neutron'], Service['neutron-server-stop'], ],
   }
   service { "neutron-metadata-agent":
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['neutron'], Service['neutron-server-stop'], ],
   }
   service { "neutron-l3-agent":
      ensure => stopped,
      enable => false,
      before => [ Ostack_controller::Dropdb['neutron'], Service['neutron-server-stop'], ],
   }
   service { "neutron-server-stop":
      name   => 'neutron-server',
      ensure => stopped,
      enable => false,
      before => Ostack_controller::Dropdb['neutron'],
   }

   ostack_controller::dropdb { 'neutron':
     dbtype  => $dbtype,
     dbname  => 'neutron',
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }

   # Make sure neutron packages are removed
   package { 'neutron-server-uninstall':
      name   => 'neutron-server',
      ensure => absent,
      require => Ostack_controller::Dropdb['neutron'],
   } 
   package { 'neutron-plugin-ml2-uninstall':
      name   => 'neutron-plugin-ml2',
      ensure => absent,
      require => Ostack_controller::Dropdb['neutron'],
   } 
   package { 'neutron-linuxbridge-agent-uninstall':
      name   => 'neutron-linuxbridge-agent',
      ensure => absent,
      require => Ostack_controller::Dropdb['neutron'],
   } 
   package { 'neutron-l3-agent-uninstall':
      name   => 'neutron-l3-agent',
      ensure => absent,
      require => Ostack_controller::Dropdb['neutron'],
   } 
   package { 'neutron-dhcp-agent-uninstall':
      name   => 'neutron-dhcp-agent',
      ensure => absent,
      require => Ostack_controller::Dropdb['neutron'],
   } 
   package { 'neutron-metadata-agent-uninstall':
      name   => 'neutron-metadata-agent',
      ensure => absent,
      require => Ostack_controller::Dropdb['neutron'],
   } 
}
