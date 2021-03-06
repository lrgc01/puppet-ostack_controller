class ostack_controller ( 
   $etcd_host = undef, 
   $etcd_host_ip = undef, 
   $mysql_cli_host = $::hostname, 
   $mysql_cli_pkg = 'mariadb-client-core-10.0', 
   $dbserv   = 'ostackdb',
   $dbrootpass = 'docker',
   $mq_proto  = 'rabbit',
   $mq_real_hostname     = undef,
   $mq_user  = 'openstack',
   $mq_pass  = 'raatomos3',
   $mq_host  = "$mq_real_hostname",

) {

# Globally used
   # execute 'apt-get update'
   exec { 'apt-update':                    # exec resource named 'apt-update'
     command => '/usr/bin/apt-get update',  # command this resource will run
     refreshonly => true,
   }

# Install base

### This should be installed in all openstack machines:
   
   # install base client package
   package { 'python-openstackclient':
     name => 'python-openstackclient',     # not needed if its the same as title
     require => Exec['apt-update'],        # require 'apt-update' before installing
     ensure => installed,
   }
####

### Specific hosts

   # In case this host is expected to run etcd, mysql-client (admin DB),
   if $::hostname ==  "${etcd_host}" {
      # etcd rund on one host only
      package { 'etcd':
         name => 'etcd',     		   # not needed if its the same as title
         require => Exec['apt-update'],        # require 'apt-update' before installing
         ensure => installed,
      }
      # ensure apache2 service is running
      service { 'etcd':
         require => Package['etcd'],
         enable => true,
         ensure => running,
      }
      # ensure correct dir and config file etcd.conf.yml file exist
      file { '/etc/default/etcd':
         ensure  => present,
         require => Package['etcd'],
         content => "DAEMON_ARGS=\"--name  ${etcd_host} --data-dir  /var/lib/etcd --initial-cluster-state  \'new\' --initial-cluster-token  \'etcd-cluster-01\' --initial-cluster  ${etcd_host}=http://${etcd_host_ip}:2380 --initial-advertise-peer-urls  http://${etcd_host_ip}:2380 --advertise-client-urls  http://${etcd_host_ip}:2379 --listen-peer-urls  http://0.0.0.0:2380 --listen-client-urls  http://${etcd_host_ip}:2379\"",
	 notify  => Exec['restart_etcd'],
      } 
      # restart for each change in file
      exec { restart_etcd:
         path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
         refreshonly => true,
         command     => "systemctl restart etcd",
      }

   }
   # If this host is supposed to be DB admin with mysql/mariadb CLI
   # Up to now, the mysql_cli_host must be de controller
   if $::hostname == "$mysql_cli_host" {
      class { 'ostack_controller::definedbsrv':
           cli_name => 'mariadb-client-core-10.0',
           dbserv   => 'ostackdb',
           dbrootpass => 'docker',
      }
   }
   # If this is the mq server:
   if $::hostname == "$mq_real_hostname" {
	 # Up to now, only rabbitmq
      if "$mq_proto" == 'rabbit' {
         # Must set $mq_real_hostname to run the class
         class { 'ostack_controller::rabbitthishost':
	    mq_real_hostname => "$mq_real_hostname",
            mq_user  => "$mq_user",
            mq_pass  => "$mq_pass",
         }
      }
   }
}

