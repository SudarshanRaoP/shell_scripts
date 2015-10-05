#!/bin/bash

clear
echo -e "\t\t[+]Chef installer[+]"
echo
echo "#Author: Sudarshan Rao <sudarshan.visham188@gmail.com>"
echo "#Linux Distribution: RedHat/CentOS 7/6/5 and Ubuntu trusty/precise/lucid"
echo "#Arch: x86_64 or amd64 (64 bit)"
echo "======================================================"
echo


get_system_info(){
if test -f "/etc/lsb-release" && grep -q DISTRIB_ID /etc/lsb-release; then
  platform=`grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]'`
  platform_code=`grep DISTRIB_CODENAME /etc/lsb-release | cut -d "=" -f 2`
  platform_version=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2`
elif test -f "/etc/redhat-release"; then
  platform=`sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]'| cut -d ' ' -f 1`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d '.' -f 1`
else
  echo "This script only supports Redhat/CentOS and Ubuntu"
  return 1
fi
}

get_system_arch(){
  machine=`uname -m`
  if [[ $machine == "x86_64" ]]; then
    case "$platform" in
    "redhat"|"centos")
      system_arch="x86_64"
    ;;
    "ubuntu")
      system_arch="amd64"
    ;;
    esac
  else
   echo "System architecture is not 64 bit."
    return 1
  fi
}

validate_system_info(){
  case $platform in
  "ubuntu")
    for version in "trusty" "precise" "lucid"
      do if [[ "$version" == $platform_code ]]; then return 0;fi
    done
  ;;
  "redhat"|"centos")
    for version in 7 5 6
      do if $version == $platform_version; then return 0; fi
    done
  ;;
  *)
   echo "$platform $platform_version is not supported by Chef Server."
   return 1
  esac
}
validate_info_chefdk(){
  case ${platform} in
  "ubuntu")
  for version in "12.04" "13.10" "14.04"
    do if [[ "$version" == $platform_version ]]; then return 0 ;fi
  done
  ;;
  "redhat"|"centos")
  for version in 7 6
    do if "$version" == $platform_version; then return 0; fi
  done
  ;;
  esac
}
do_curl() {
  echo "trying curl..."
  curl -sL -D ./chef_installer.stderr "$1" > "$2"
  rc=$?
  # check for 404
  grep "404 Not Found" ./chef_installer.stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    echo "ERROR 404"
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "curl"
    return 1
  fi

  return 0
}

do_python() {
  echo "trying python..."
  python -c "import sys,urllib2 ; sys.stdout.write(urllib2.urlopen(sys.argv[1]).read())" "$1" > "$2" 2>./chef_installer.stderr
  rc=$?
  # check for 404
  grep "HTTP Error 404" ./chef_installer.stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    echo "ERROR 404"
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "python"
    return 1
  fi
  return 0
}
download_file(){
 if [ $? -eq 0 ];then
 wget --no-check-certificate $1 -O $2 2>&1 >./chef_installer.stderr
 else
   exit 1
 fi
}
validate_url(){
  if exists curl;then
    do_curl $1 $2
  fi
  rc=$?
  if exists python;then
    do_python $1 $2 && return 0
  fi
  if [ $rc -ne 0 ] && [ $? -ne 0 ]; then
  echo "Unable to download file"
    return 1
  fi
}
install_server(){
echo -n "Enter Chef server version to install.[Default: 12.2.0] : " && read CHEF_SERVER_VERSION
if $CHEF_SERVER_VERSION == "" ;then
  CHEF_SERVER_VERSION=12.2.0
fi
get_system_info
get_system_arch
validate_system_info
if [ $? -eq 0 ];then
case "${platform}" in
  "ubuntu")     
  chef_download_url=https://web-dl.packagecloud.io/chef/stable/packages/${platform}/${platform_code}/chef-server-core_${CHEF_SERVER_VERSION}-1_${system_arch}.deb
  chef_download_file=chef-server-core_${CHEF_SERVER_VERSION}-1_${system_arch}.deb
  validate_url ${chef_download_url} ${chef_download_file}
  download_file ${chef_download_url} ${chef_download_file}
  sudo dpkg -i ${chef_download_file} 2>&1 >/dev/null
  return 0
  ;;
  "redhat"|"centos")
  chef_download_url=https://web-dl.packagecloud.io/chef/stable/packages/el/${platform_version}/chef-server-core-${CHEF_SERVER_VERSION}-1.el${platform_version}.${system_arch}.rpm
  chef_download_file=chef-server-core-${CHEF_SERVER_VERSION}-1.el${platform_version}.${system_arch}.rpm
    validate_url ${chef_download_url} ${chef_download_file}
  download_file ${chef_download_url} ${chef_download_file}
  sudo rpm -i ${chef_download_file}
  return 0
  ;;
  esac
else
  exit 0
fi
}

server_reconfigure(){
  sudo chef-server-ctl reconfigure
}

user_input(){
echo "Chef administration configuration:"
echo -n "Admin username: " && read USERNAME
echo -n "First Name: " && read FIRSTNAME
echo -n "Last Name: " && read LASTNAME
echo -n "Email: " && read EMAIL
echo -n "Password: " && read PASSWORD
echo -n "User .pem directory: " && read USER_PEM_DIR
}

org_input(){
echo "Organization Admin Configuration"
echo -n "Organization short name: " && read ORG_SHORT
echo -n "Organization full name: " && read ORG_FULL
echo -n "Organization Admin username: " && read ORG_ADMIN
echo -n "Organization validator.pem directory: " && read ORG_PEM_DIR

}

validate_user(){
  for users in `sudo chef-server-ctl user-list`
    do
      if [ $USERNAME == $users ] || [ -f ${USER_PEM_DIR}/${USERNAME}.pem ]
        then 
          echo "Either username '$USERNAME' or ${USER_PEM_DIR}/${USERNAME}.pem file already exists!"
          echo "Aborting!!"
          return 4
        fi
  done
}

validate_org(){
 for orgs in `sudo chef-server-ctl org-list`
   do
     if [ "$ORG_SHORT" == $orgs ] || [ -f "${ORG_PEM_DIR}/${ORG_SHORT}-validator.pem" ]
       then
         echo "Either organization $ORG_SHORT or ${ORG_PEM_DIR}/${ORG_SHORT}-validator.pem file already exists!!"
         echo "Aborting!!"
         return 4
     fi
done
}

create_user(){
  validate_user
  if [ $? -ne 4 ] ; then
  sudo chef-server-ctl user-create $USERNAME $FIRSTNAME $LASTNAME $EMAIL $PASSWORD --filename ${USER_PEM_DIR}/${USERNAME}.pem > /dev/null 2>&1
  chmod 400 ${USER_PEM_DIR}/${USERNAME}.pem > /dev/null 2>&1
  fi
}

create_org(){
  validate_org
  if [ $? -ne 4 ]; then
  sudo chef-server-ctl org-create $ORG_SHORT $ORG_FULL -a $ORG_ADMIN --filename ${ORG_PEM_DIR}/${ORG_SHORT}-validator.pem > /dev/null 2>&1
  chmod 400 ${ORG_PEM_DIR}/${ORG_SHORT}-validator.pem > /dev/null 2>&1
  fi
}

install_management_console(){
  sudo chef-server-ctl install opscode-manage
  sudo opscode-manage-ctl reconfigure
  sudo chef-server-ctl reconfigure
}

print_usage(){
echo "Usage: $0"
echo -e "\tOptions:"
echo -e "\t\t-s : Install server."
echo -e "\t\t-u : Create user account."
echo -e "\t\t-o : Create organization."
echo -e "\t\t-c : Install Chef-dk."
echo -e "\t\t-b [file] : Bootstrap nodes in file."
echo -e "\t\t-x [username] : Username."
echo -e "\t\t-P [Password] : Password."
}

install_chef_dk(){
echo -n "Enter Chefdk version to install. [Default : 0.8.1] : " && read CHEF_DK_VERSION
if [[ ${CHEF_DK_VERSION} == "" ]];then
  CHEF_DK_VERSION=0.8.1
fi
get_system_info
get_system_arch
validate_info_chefdk
if [ $? -eq 0 ]; then
case $platform in
  "ubuntu")
  CHEF_DK_URL=https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/${platform_version}/`uname -m`/chefdk_${CHEF_DK_VERSION}-1_${system_arch}.deb
  CHEF_DK_FILE=chefdk_${CHEF_DK_VERSION}-1_${system_arch}.deb
  validate_url ${CHEF_DK_URL} ${CHEF_DK_FILE}
  download_file ${CHEF_DK_URL} ${CHEF_DK_FILE}
  dpkg -i $CHEF_DK_FILE
  ;;
  "redhat"|"centos")
  CHEF_DK_URL=https://opscode-omnibus-packages.s3.amazonaws.com/el/${platform_version}/${system_arch}/chefdk-${CHEF_DK_VERSION}-1.el${platform_vesion}.${system_arch}.rpm
  CHEF_DK_FILE=chefdk-${CHEF_DK_VERSION}-1.el${platform_vesion}.${system_arch}.rpm
  validate_url ${CHEF_DK_URL} ${CHEF_DK_FILE}
  download_file ${CHEF_DK_URL} ${CHEF_DK_FILE}
  rpm -i $CHEF_DK_FILE
 ;;
 esac
else
  exit 1
fi
}

bootstrap_nodes(){
   if [ -n "$1" ] && [ -n "$2" ] && [ -n $3 ]; then
   for node in `cat $3`
     do
       node_ip_host=`echo $node |cut -d "\t" -f 1`
       node_name=`echo $node |cut -d "\t" -f 2`
       knife bootstrap $node_ip_host -x $1 -P $2 -N $node_name --sudo
   done
   else
     echo "Bootstrap usage: chef_installer.sh -b -x <username> -P <password> -f <file>"
     exit 1
   fi
}


while getopts suochb:x:P:f opts; do
  case $opts in
    s)
    install_server
    server_reconfigure
    sudo chef-server-ctl start
    install_management_console
    ;;
    u)
    user_input
    create_user
    ;;
    o)
    org_input
    create_org
    ;;
    h)
    print_usage
    ;;
    c)
    install_chef_dk
    ;;
    x)
    if [[ $OPTARG != "" ]]; then
    user=$OPTARG
    fi;;
    P)
    if [[ $OPTARG != "" ]];then
    password=$OPTARG
    fi;;
    f)
    if [[ $OPTARG != "" ]];then
    node_list=$OPTARG
    fi;;
    b)
    bootstrap_nodes $user $password $node_list
    ;;
    esac
  done
