#!/bin/bash

print_msg(){
  echo "[+] $*"
}

print_usage(){
  echo -e "Usage: ansible-installer.sh -h <hostfile> -u <superuser/root> -p <user's password>"
  echo -e "\tWhere:"
  echo -e "\t\t-h <hostfile> : File containing newline separated hostnames of hosts to be managed by ansible."
  echo -e "\t\t-u <superuser>: User with enough privileges. Default is 'root'."
  echo -e "\t\t-p <password> : Password for ssh key imports."
}

remote_user=root

install_deps(){
  print_msg Installing dependencies
  yum update -y epel-release python-simplejson libselinux-python sshpass
}

install_ansible(){
  print_msg Installing ansible
  yum install -y ansible
}

prepare_hosts(){
  for host in `cat $1`;do
    print_msg Adding ssh keys to $host
    sshpass -p$3 ssh-copy-id $2@$host
  done

  for host in `cat $1`;do
    print_msg Preparing $host
    ssh $2@$host "yum install -y python-simplejson libselinux-python"
  done
}

test_ansible(){
  for host in `cat $1`;do
    print_msg Testing connection to $host
    ansible $host -m raw -a "echo success" -u $2
  done
}

while getopts h:u::p: opts; do
    case $opts in
        h)
        if [[ -f $OPTARG ]];then
        hostfile=$OPTARG
        else
        print_msg File $OPTARG does not exist.
        exit
        fi
        ;;
        u)
        if [[ -z "$OPTARG" ]];then
        print_msg User not provided. Using 'root' as user.
        else
        remote_user=$OPTARG
        fi
        ;;
        p)
        if [[ -z "$OPTARG" ]];then
        print_msg Password not provided.
        exit
        else
        password=$OPTARG
        fi
        ;;
        *)
        print_usage
        exit
        ;;
    esac
done

if [[ "$#" -eq 0 ]];then
  print_msg No arguments provided.
  exit
  else
  install_deps
  install_ansible
  prepare_hosts $hostfile $remote_user $password
  test_ansible $hostfile $remote_user
fi
