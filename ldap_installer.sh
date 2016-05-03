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
    LDAPDB="{2}hbd,cn=config"
  else
    print_msg Unsupported OS version
    exit
  fi
}

generate_pw(){
PW=`slappasswd -s $PASSWORD`
}

configure_ldap(){

prin_msg Configuring domain
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

while getopts a:d:P:i opts; do
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
        *)
        print_usage
        ;;
    esac
done
