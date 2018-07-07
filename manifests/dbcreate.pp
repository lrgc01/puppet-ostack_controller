define ostack_controller::dbcreate ( 
  $dbtype = 'mysql',
  $dbname = undef, 
  $dbuser = undef, 
  $dbpass = 'root',
  $dbhost = 'localhost'
) {

include ostack_controller::definedbsrv

  # Only go ahead if named db
  if $dbname {
     if "$dbtype" == 'mysql' {
        exec { "create-$dbname":
           path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
           environment => ['HOME=/root','USER=root'],
           require     => Package['mysql-client'],
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
