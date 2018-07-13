# Extra check:
#    Runs only if this is the real machine to run
class ostack_controller::rabbitthishost (
   $mq_real_hostname     = undef,
   $mq_user  = 'openstack',
   $mq_pass  = 'raatomos3',
   $mq_host  = 'rabbitmq',
)
{
   if "$::hostname" == "$mq_real_hostname" {
      package { 'rabbitmq-server':
         ensure  => present,
      }
      service { 'rabbitmq-server':
         ensure  => running,
         require => Package['rabbitmq-server'],
         enable  => true,
         notify  => Exec['grant-user-rabbit'],
      }
      exec {'grant-user-rabbit':
         path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
         require     => Package['rabbitmq-server'],
         refreshonly => true,
         command     => "rabbitmqctl add_user $mq_user $mq_pass && rabbitmqctl set_permissions $mq_user \".*\" \".*\" \".*\" ",
      }
   }
}
