class ostack_controller ( 
   $etcd_host = undef, 
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

   # In case this host is expected to run etcd
   case $::hostname { 
      "${etcd_host}": {
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
            content => 'DAEMON_ARGS="--name  controller --data-dir  /var/lib/etcd --initial-cluster-state  \'new\' --initial-cluster-token  \'etcd-cluster-01\' --initial-cluster  controller=http://192.168.56.196:2380 --initial-advertise-peer-urls  http://192.168.56.196:2380 --advertise-client-urls  http://192.168.56.196:2379 --listen-peer-urls  http://0.0.0.0:2380 --listen-client-urls  http://192.168.56.196:2379"',
	    notify  => Exec['restart_etcd'],
         } 
         # restart for each change in file
         exec { restart_etcd:
            path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
            refreshonly => true,
            command     => "systemctl restart etcd",
         }
   
      }
   }

}

