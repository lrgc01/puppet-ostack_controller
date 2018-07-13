#
# This is intended to be run from the machine(s) which should control the DB server
#
define ostack_controller::dropdb ( 
  $dbtype = 'mysql',
  $dbname = undef, 
  $dbuser = undef, 
  $dbpass = 'root',
  $dbhost = 'localhost'
) {

# Ensure can access DB server as admin
include ostack_controller::definedbsrv 

  # Only go ahead if named db
  if $dbname {
     if "$dbtype" == 'mysql' {
        exec { "drop-$dbname":
           path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
           environment => ['HOME=/root','USER=root'],
           onlyif      => "test x`echo $(mysql -s -e \"show databases;\" | grep -w $dbname)` = x\"$dbname\"",
           command     => "mysql -s -e 'drop database '\"$dbname\"';'",
        }
     }
  }
}
