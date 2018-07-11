### Basic OpenStack **controller** node installation module based on Pike (for Ubuntu 16.04)

 - Can install and run etcd on specific server
 - Base classes to create and populate databases
   - Configure the db manager machine (mysql client install, my.cnf defs)
 - Install keystone and its dependencies
   - It creates base users, roles, projects.
 - Install glance and its dependencies 
   - It creates endpoints, user, project and add role.
 - Install nova and its dependencies
   - It creates endpoints, user, project and add role.
   - (Including placement)
 - Install neutron and its dependencies (working on)
   - It creates endpoints, user, project and add role.
 - Install and configure horizon (to do)
   - Access http://controler:3000/horizon
