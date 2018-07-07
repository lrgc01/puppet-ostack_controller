class ostack_controller::definedbsrv {
   # Config to administer database mysql
   file { '/root/.my.cnf':
      name    => '/root/.my.cnf',
      ensure  => present,
      recurse => remote,
      mode    => '0600',
      source  => 'puppet:///modules/ostack_controller/my.cnf.root',
   }
   # Also make sure this host has the necessary tools to administer the mysql DB server
   package { 'mysql-client':
        name    => 'mariadb-client-core-10.0',
        ensure  => present,
   }
}
