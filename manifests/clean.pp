class lamp::clean {
   # clean left over packages after removal of main package
   exec { 'autoremove':
     command => '/usr/bin/apt -y autoremove',
     refreshonly => true,
   }
   
   # ensure apache2 service is stopped and disabled
   service { 'apache2':
     enable => false,
     ensure => stopped,
     before => Package['apache2'],
   }
   
   # deinstall apache2 package
   package { 'apache2':
     ensure => absent,
     before => Package['php'],
   }
   
   # ensure info.php file has been removed
   file { '/var/www/html/info.php':
     ensure => absent,
     before => Package['php'],
   } 

   # deinstall php package
   package { 'php':
     ensure => absent,
     before => Service['mysql'],
   }

   # ensure mysql-server service is stopped and disabled
   service { 'mysql':
     enable => false,
     ensure => stopped,
     before => Package['mysql-server'],
   }
   
   # deinstall mysql-server package
   package { 'mysql-server':
     ensure => absent,
     notify => Exec['autoremove'],        # clean after all of them
   }
   
}

