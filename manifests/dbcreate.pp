#
# This is intended to be run from the machine(s) which should control the DB server
#
define ostack_controller::dbcreate ( 
  $dbtype = 'mysql',
  $dbname = undef, 
  $dbuser = undef, 
  $dbpass = 'root',
  $dbhost = 'localhost'
) {

# May use $cli_name to change the name of the package to be installed (double check!)
# Example:
# cli_name => 'mariadb-client-core-10.1'
# current: $cli_name = 'mariadb-client-core-10.0'
#

  # Only go ahead if named db
  if $dbname {
     if "$dbtype" == 'mysql' {
        exec { "create-$dbname":
           path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
           environment => ['HOME=/root','USER=root'],
           require     => Package['db-client'],
           subscribe   => File['/root/.my.cnf'],
           onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` != x\"$dbname\"",
           command     => "mysql -s -e 'create database '\"$dbname\"';'",
           notify      => Exec["grant-user-$dbname"]
        }
        exec { "grant-user-$dbname":
           path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
           environment => ['HOME=/root','USER=root'],
           refreshonly => true,
           command     => "mysql -s -e \"GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'%' IDENTIFIED BY '$dbpass';\"",
        }
     }
       
    # Creation of DB
  }
}
