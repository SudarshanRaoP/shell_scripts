# shell_scripts

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

To bootstrap nodes:

	chef_installer.sh -b -x <username> -P <password> -f <file>
