# This should be ran only on the controller node
#
define ostack_controller::uninstall::keystone (
     $dbtype  = 'mysql',
     $dbname  = 'keystone',
     $dbuser  = 'keystone',
     $dbpass  = 'keatomos3',
     $dbhost  = 'ostackdb',
) {

   # Makes sure keystone, apache2 and libapache2-mod-wsgi are installed
   package { 'keystone-uninstall':
      name    => 'keystone',
      ensure  => absent,
      require   => Package['libapache2-mod-wsgi-uninstall'],
   }
   package { 'libapache2-mod-wsgi-uninstall':
      name    => 'libapache2-mod-wsgi',
      ensure  => absent,
      notify  => Exec['restart-apache2'],
   }
   exec { 'restart-apache2':
      path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      environment => ['HOME=/root','USER=root'],
      refreshonly => true,
      command     => "systemctl restart apache2",
   }

   # Create keystone database
   ostack_controller::dropdb { 'keystone':
     dbtype  => $dbtype,
     dbname  => $dbname,
     dbuser  => $dbuser,
     dbpass  => $dbpass,
     dbhost  => $dbhost,
   }
}
