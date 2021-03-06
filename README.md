# shell_scripts

* chef_installer.sh : Installer for Chef Server and Client
* zeppelin_installer.sh : Installer for Apache Zeppelin


#chef_installer.sh


Usage : chef_installer.sh [options]
   
	Options: 
		-s		:	Install Chef server
		-u		:	Create user.
		-o		:	Create organization.
		-c		:	Install Chef-dk
		-b		:	Bootstrap nodes.
		-x <username>	:	Username.
		-P <password>	:	Password.
		-f <file>	:	List of node ipaddress and name.

To install Chef server:

	chef_installer.sh -s

To install Chef-dk:

	chef_installer.sh -c

To create user account:

	chef_installer.sh -u

To create organization:

	chef_installer.sh -o

To configure knife:

	1. Create your chef repository directory. e.g. ‘mkdir chef-repo’
	2. Create ‘.chef’ directory inside your chef repository directory. e.g. mkdir ‘mkdir .chef’
	3. Put ‘knife.rb’ file inside ‘.chef’ directory. Which can be acquired from Chef management console 'Administration' page by selecting an organization and clicking on 'Generate knife config'.
	4. Copy USERNAME.pem and ORGANIZATION-validator.pem into ‘.chef’ directory. [They can be found in /etc/chef/ dir on chef-server machine]
	5. Create ‘trusted_certs’ directory inside ‘.chef’ directory, for ssl certificates.
	6. Run ‘knife ssl fetch’ to get ssl certificate from chef-server.
	7. Change permissions on .pem and .crt files to 444.
	8. Verify ssl connection using ‘knife ssl check’.
To bootstrap nodes:

	chef_installer.sh -b -x <username> -P <password> -f <file>


#zeppelin-installer.sh

```shell
	chmod +x zeppelin-installer.sh
	./zeppelin-installer.sh
```

#ldap_installer.sh
```shell
	chmod +x ldap_installer.sh
	./ldap_installer.sh -a Manager -d dc=example,dc=com -P mypassword -i
```

#ldap_replication.sh
```shell
Usage: 
	ldap_replication.sh [options <args>] <action>
		Where options are:
			-i <ID> : Unique ID for LDAP Server. Must be different on different servers.
		-b <bind dn> : DN for binding to the other server E.g. cn=admin,dc=example,dc=com.
			-B <search base> : E.g. dc=example,dc=com
			-p <Provider> : Other LDAP server URL. E.g. ldap://server.example.com:389
			-P <Password> : Password for binddn. E.g. mypassword
		Where action is:
		-e : Enable replication
Example:
	ldap_replication.sh -i 0 -b cn=admin,dc=example,dc=com -p ldap://server2.example.com -P mypassword -B ou=Users,dc=example,dc=com -e
		-m : Modify replication
Example:
	ldap_replication.sh -i 0 -b cn=admin,dc=example,dc=com -p ldap://server2.example.com -P password -B dc=example,dc=com -m
```
Note: `-i` and `-p` must be different on different servers.

#ansible-installer.sh
```shell
   chmod +x ansible-installer.sh
   #hostfile contains hosts (newline separated) to be managed by ansible.
   ./ansible-installer.sh -h hostfile -u root -p password
```
