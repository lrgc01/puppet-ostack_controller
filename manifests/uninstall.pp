class ostack_controller::uninstall (
     $dbtype  = 'mysql',
     $dbhost  = 'ostackdb',
     $neutrondbname  = 'neutron',
     $neutrondbuser  = 'neutron',
     $neutrondbpass  = 'neatomos3',
     $neutrondbhost  = $dbhost,
     $novadbname  = 'nova',
     $novadbuser  = 'nova',
     $novadbpass  = 'noatomos3',
     $novadbhost  = $dbhost,
     $glancedbname  = 'glance',
     $glancedbuser  = 'glance',
     $glancedbpass  = 'glatomos3',
     $glancedbhost  = $dbhost,
     $keystonedbname  = 'keystone',
     $keystonedbuser  = 'keystone',
     $keystonedbpass  = 'keatomos3',
     $keystonedbhost  = $dbhost,
) {
#########
# Uninstalation procedures
#
   ostack_controller::uninstall::neutron { 'neutron':
     dbtype  => $dbtype,
     dbname  => $neutrondbname,
     dbuser  => $neutrondbuser,
     dbpass  => $neutrondbpass,
     dbhost  => $neutrondbhost,
     before  => Ostack_controller::Uninstall::Nova['nova'],
   }
   ostack_controller::uninstall::nova { 'nova':
     dbtype  => $dbtype,
     dbname  => $novadbname,
     dbuser  => $novadbuser,
     dbpass  => $novadbpass,
     dbhost  => $novadbhost,
     before  => Ostack_controller::Uninstall::Glance['glance'],
   }
   ostack_controller::uninstall::glance { 'glance':
     dbtype  => $dbtype,
     dbname  => $glancedbname,
     dbuser  => $glancedbuser,
     dbpass  => $glancedbpass,
     dbhost  => $glancedbhost,
     before  => Ostack_controller::Uninstall::Keystone['keystone'],
   }
   ostack_controller::uninstall::keystone { 'keystone':
     dbtype  => $dbtype,
     dbname  => $keystonedbname,
     dbuser  => $keystonedbuser,
     dbpass  => $keystonedbpass,
     dbhost  => $keystonedbhost,
   }
}
