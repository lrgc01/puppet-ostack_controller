#
# Installation of the admin package, i.e. mysql/mariadb client, on the 
# machine supposed to administer the DB server.
#
class ostack_controller::definedbsrv (
   $cli_name   = 'mariadb-client-core-10.0',
   $dbserv     = 'ostackdb',
   $dbrootpass = 'docker',
)
{
   # Config to administer database mysql
   file { '/root/.my.cnf':
      name    => '/root/.my.cnf',
      ensure  => present,
      mode    => '0600',
      content => template('ostack_controller/my.cnf.root.erb'),
   }
   # Also make sure this host has the necessary tools to administer 
   # the mysql DB server
   package { 'db-client':
        name    => $cli_name,
        ensure  => present,
   }
}
