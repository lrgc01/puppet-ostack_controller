# This should be ran only on the controller node
#
define ostack_controller::services::keystone (
     $enable   = undef,
     $ensure   = undef,
     $restart  = undef,
) {

   $service_hash_attr = { enable => $enable, 
   			  ensure => $ensure , 
			}
   $array_services    = [ 'apache2' ]
   $services          = "apache2"

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
