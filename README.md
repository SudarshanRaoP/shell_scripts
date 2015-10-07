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
