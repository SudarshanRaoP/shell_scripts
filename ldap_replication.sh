#!/bin/bash

print_msg(){
	echo "[+] $*"
}

print_usage(){
  echo -e "Usage: "
	echo -e "\tldap_replication.sh [options <args>] <action>"
	echo -e "\t\tWhere options are:"
	echo -e "\t\t\t-i <ID> : Unique ID for LDAP Server. Must be different on different servers."
	echo -e "\t\t-b <bind dn> : DN for binding to the other server E.g. cn=admin,dc=example,dc=com".
	echo -e "\t\t\t-B <search base> : E.g. dc=example,dc=com"
	echo -e "\t\t\t-p <Provider> : Other LDAP server URL. E.g. ldap://server.example.com:389"
	echo -e "\t\t\t-P <Password> : Password for binddn. E.g. mypassword"
  echo -e "\t\tWhere action is:"
  echo -e "\t\t-e : Enable replication"
  echo -e "Example:"
  echo -e "\tldap_replication.sh -i 0 -b cn=admin,dc=example,dc=com -p ldap://server2.example.com -P mypassword -B ou=Users,dc=example,dc=com -e"
  echo -e "\t\t-m : Modify replication"
  echo -e "Example:"
  echo -e "\tldap_replication.sh -i 0 -b cn=admin,dc=example,dc=com -p ldap://server2.example.com -P password -B dc=example,dc=com -m"
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

add_syncprov(){
#Add syncprov module
ldapadd -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulePath: /usr/lib64/openldap
olcModuleLoad: syncprov.la
EOF

ldapadd -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcOverlay=syncprov,olcDatabase=$LDAPDB
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpSessionLog: 100
EOF
}

configure_replication(){
# olcServerID must be different on different servers
ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcServerID
olcServerID: $ID
EOF
#Provider must be different of different servers
ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase=$LDAPDB
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=001 provider=$PROVIDER bindmethod=simple binddn="$BINDDN" credentials=$PASSWORD searchbase="$BASE" scope=sub schemachecking=on type=refreshAndPersist retry="30 5 300 3" interval=00:00:05:00
-
add: olcMirrorMode
olcMirrorMode: TRUE
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcOverlay=syncprov,olcDatabase=$LDAPDB
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
EOF
}

modify_replication(){
# olcServerID must be different on different servers
ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcServerID
olcServerID: $ID
EOF
#Provider must be different of different servers
ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase=$LDAPDB
changetype: modify
replace: olcSyncRepl
olcSyncRepl: rid=001 provider=$PROVIDER bindmethod=simple binddn="$BINDDN" credentials=$PASSWORD searchbase="$BASE" scope=sub schemachecking=on type=refreshAndPersist retry="30 5 300 3" interval=00:00:05:00
-
replace: olcMirrorMode
olcMirrorMode: TRUE
EOF

}

while getopts i:b:B:p:P:em opts; do
    case $opts in
        i)
        if [[ "$OPTARG" == "" ]];then
           print_msg Server ID is missing.
           exit
        else
           ID=$OPTARG
        fi
        ;;
        b)
		if [[ "$OPTARG" == "" ]];then
			print_msg Bind DN is missing.
			exit
		else
			BINDDN=$OPTARG
		fi
		;;
        p)
        if [[ "$OPTARG" == "" ]];then
           print_msg Provider is missing.
           exit
        else
           PROVIDER=$OPTARG
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
        B)
        if [[ "$OPTARG" == "" ]];then
           print_msg Search base is missing.
           exit
        else
           BASE=$OPTARG
        fi
        ;;
        e)
        get_os_version
        add_syncprov
        configure_replication
        ;;
        m)
        get_os_version
        modify_replication
        ;;
        h)
        print_usage
        ;;
        *)
        print_usage
        ;;
    esac
done