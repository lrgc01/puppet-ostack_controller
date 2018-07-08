#
# Installation of the admin package, i.e. mysql/mariadb client, on the 
# machine supposed to administer the DB server.
#
define ostack_controller::definedbsrv (
   $cli_name = 'mariadb-client-core-10.0',
)
{
   # Config to administer database mysql
   file { '/root/.my.cnf':
      name    => '/root/.my.cnf',
      ensure  => present,
      recurse => remote,
      mode    => '0600',
      source  => 'puppet:///modules/ostack_controller/my.cnf.root',
   }
   # Also make sure this host has the necessary tools to administer 
   # the mysql DB server
   package { 'db-client':
        name    => $cli_name,
        ensure  => present,
   }
}
