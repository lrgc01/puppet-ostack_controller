# This should be ran only on the controller node
#
class ostack_controller::services::neutron (
     $enable   = undef,
     $ensure   = undef,
     $restart  = undef,
) {

   $service_hash_attr = { enable => $enable, 
   			  ensure => $ensure , 
			}
   $array_services    = [ 'neutron-server', 'neutron-linuxbridge-agent', 'neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-linuxbridge-cleanup' ]
   $services          = "neutron-server neutron-linuxbridge-agent neutron-dhcp-agent neutron-l3-agent neutron-metadata-agent neutron-linuxbridge-cleanup"

   service { 
      default:
         * => $service_hash_attr,
      ;
      $array_services:
      ;
   }
   if $restart and ! $ensure {
      exec { 'restart':
         path        => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
         environment => [ 'HOME=/root','USER=root' ],
         command     => "systemctl restart $services",
      }
   }

}
