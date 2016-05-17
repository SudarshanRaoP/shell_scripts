#!/bin/bash

print_msg(){
  echo "[+] $*"
}

print_usage(){
        echo -e "Usage: "
	echo -e "\t\tldap_installer.sh [options <args>] <action>"
	echo -e "\t\t\tWhere options are:"
	echo -e "\t\t\t\t-a [<admin cn>] : Admin CN.E.g. Manager"
	echo -e "\t\t\t\t-d <domain component> : E.g. dc=example,dc=com"
	echo -e "\t\t\t\t-P <Password> : Password for RootDN. E.g. mypassword"
  	echo -e "\t\t\tWhere action is:"
  	echo -e "\t\t\t\t-i : Install OpenLDAP Server"
  	echo -e "Example:"
  	echo -e "\t\tldap_installer.sh -a Manager -d dc=example,dc=com -P mypassword -i"
  	echo -e "Example: Add additional schemas"
  	echo -e "\t\tldap_installer.sh -A"
}

install_ldap(){
  print_msg Installing OpenLDAP
  sudo yum install -y openldap openldap-servers openldap-clients
}

start_ldap(){
  print_msg Start slapd
  service slapd start
}

get_os_version(){
  VER=`sed 's/[^0-9]*//g' /etc/redhat-release`
  VERSION=`echo ${VER:0:1}`
  if [[ "$VERSION" == "6" ]];then
    LDAPDB="{2}bdb,cn=config"
  elif [[ "$VERSION" == "7" ]];then
    LDAPDB="{2}hdb,cn=config"
  else
    print_msg Unsupported OS version
    exit
  fi
}

generate_pw(){
PW=`slappasswd -s $PASSWORD`
}

validate_opts(){
	if [[ "$ADMIN" == "" ]];then
	print_msg Admin dn is required.
	exit
	fi
	if [[ "$DC" == "" ]];then
	print_msg Domain Component (DC) is required.
	exit
	fi
	if [[ "$PASSWORD" == "" ]];then
	print_msg Password is required.
	exit
	fi
}

configure_ldap(){
print_msg Configuring domain
#Validate options
validate_opts

ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase=$LDAPDB
changetype: modify
replace: olcSuffix
olcSuffix: $DC
EOF

print_msg Configuring RootDN
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase=$LDAPDB
changetype: modify
replace: olcRootDN
olcRootDN: cn=$ADMIN,$DC
EOF

print_msg Configuring RootPW
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase=$LDAPDB
changetype: modify
add: olcRootPW
olcRootPW: $PW
EOF

}

ldap_whoami(){
print_msg ldapwhoami:
ldapwhoami -D cn=$ADMIN,$DC -w $PASSWORD
}

add_schema(){
print_msg Creating temporary workspace
mkdir /tmp/slapd.d
cat <<EOF > new_slapd.conf
include          /etc/openldap/schema/core.schema
include          /etc/openldap/schema/cosine.schema
include          /etc/openldap/schema/nis.schema
include          /etc/openldap/schema/inetorgperson.schema
EOF
slaptest -f new_slapd.conf -F /tmp/slapd.d

cp "/tmp/slapd.d/cn=config/cn=schema/cn={1}cosine.ldif" "/etc/openldap/slapd.d/cn=config/cn=schema"
cp "/tmp/slapd.d/cn=config/cn=schema/cn={2}nis.ldif" "/etc/openldap/slapd.d/cn=config/cn=schema"
cp "/tmp/slapd.d/cn=config/cn=schema/cn={3}inetorgperson.ldif" "/etc/openldap/slapd.d/cn=config/cn=schema"

chown ldap:ldap '/etc/openldap/slapd.d/cn=config/cn=schema/cn={1}cosine.ldif'
chown ldap:ldap '/etc/openldap/slapd.d/cn=config/cn=schema/cn={2}nis.ldif'
chown ldap:ldap '/etc/openldap/slapd.d/cn=config/cn=schema/cn={3}inetorgperson.ldif'
print_msg Restarting slapd
service slapd restart
print_msg
ldapsearch -LLLQY EXTERNAL -H ldapi:/// -b cn=schema,cn=config "(objectClass=olcSchemaConfig)" dn

print_msg Cleaning temporary workspace
rm -rf /tmp/slapd.d
print_msg Done
}

while getopts a:d:P:iA opts; do
    case $opts in
        a)
        if [[ "$OPTARG" == "" ]];then
           print_msg Admin CN is missing.
           exit
        else
           ADMIN=$OPTARG
        fi
        ;;
        d)
        if [[ "$OPTARG" == "" ]];then
           print_msg Domain component is missing.
           exit
        else
           DC=$OPTARG
        fi
        ;;
        P)
        if [[ "$OPTARG" == "" ]];then
           print_msg Password is missing.
           exit
        else
           PASSWORD=$OPTARG
        fi
        ;;
        i)
        get_os_version
        install_ldap
        start_ldap
        generate_pw
        configure_ldap
        ldap_whoami
        ;;
        A)
        add_schema
        ;;
        *)
        print_usage
        ;;
    esac
done
