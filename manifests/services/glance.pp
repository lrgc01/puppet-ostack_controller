# This should be ran only on the controller node
#
define ostack_controller::services::glance (
     $enable   = undef,
     $ensure   = undef,
     $restart  = undef,
) {

   $service_hash_attr = { enable => $enable, 
   			  ensure => $ensure , 
			}
   $array_services    = [ 'glance-api', 'glance-registry' ]
   $services          = "glance-api glance-registry"

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
