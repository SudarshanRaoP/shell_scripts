#!/bin/bash
set -e

print_msg(){
	echo "[+] $*"
}

print_usage(){
	echo -e "Usage: "
	echo -e "\t\thbaseutil.sh [options <args>] <action>"
	echo -e "\t\t\tWhere options are:"
	echo -e "\t\t\t\t-c [<table name>] : Consistency check."
	echo -e "\t\t\t\t-e <table name> : Enable replication on <table name>."
	echo -e "\t\t\t\t-d <table name> : Disable replication on <table name>."
	echo -e "\t\t\t\t-c <table name> : copy <table name> to target peer."
	echo -e "Example: "
	echo -e "\t\thbaseutil.sh -c table_name"
	echo -e "\t\thbaseutil.sh -c '' "
	echo
	echo -e "Example: "
	echo -e "\t\thbaseutil.sh -e table_name"
	echo
	echo -e "Example: "
	echo -e "\t\thbaseutil.sh -d table_name"

	echo -e "\t\thbaseutil.sh -S <starttime> -E <endtime> -P <peer.adr> -A '<additional opts>' -C <table name>" 
	echo -e "\t\thbaseutil.sh -S <starttime> -E <endtime> -i <ID> -A '<additional opts>' -V <table name>" 
}

check_consistency(){
if [[ `whoami` != "hbase" ]];then
print_msg "This operation can only be performed as 'hbase'."
else
print_msg "Checking consistency ..."
hbase hbck $1
fi
}
enable_replication(){
print_msg "Enabling replication on table : $1"
hbase shell << EOF
enable_table_replication $1
EOF
}

disable_replication(){
print_msg "Disabling replication on table : $1"
hbase shell << EOF
disable_table_replication $1
EOF
}

copy_table(){
	print_msg "Copying table : $1"
	hbase org.apache.hadoop.hbase.mapreduce.CopyTable --starttime=$STARTTIME --endtime=$ENDTIME --peer.adr=$PEER $ADDOPTS $1
}

verify_replication(){
print_msg "Verifying replication: $1"
HADOOP_CLASSPATH=`${HBASE_HOME}/bin/hbase classpath` hadoop jar $HBASE_HOME/lib/hbase-server.jar verifyrep --starttime=$STARTTIME --stoptime=$ENDTIME $ADDOPTS $ID $1 
}

while getopts c::e:d:f:C:S:E:P:A:h:i:V: opts;do
	case $opts in
		c)
		if [[ "$OPTARG" != "" ]];then
			check_consistency $OPTARG
		else
			check_consistency 
		fi
		;;
		e)
		enable_replication $OPTARG
		;;
		d)
		disable_replication $OPTARG
		;;
		S)
		if [[ "$OPTARG" != "" ]];then
			STARTTIME=$OPTARG
		else
			print_msg "No startime provided."
			exit
		fi
		;;
		E)
		if [[ "$OPTARG" != "" ]];then
			ENDTIME=$OPTARG
		else
			print_msg "No endtime provided."
			exit
		fi
		;;
		P)
		if [[ "$OPTARG" != "" ]];then
			PEER=$OPTARG
		else
			print_msg "No peer.adr provided."
			exit
		fi
		;;
		A)
		if [[ "$OPTARG" != "" ]];then
			ADDOPTS=$OPTARG
		else
			print_msg "No additional options provided."
		fi
		;;
		C)
		if [[ "$OPTARG" != "" ]];then
			copy_table $OPTARG
		else
			print_msg "No table provided for copy."
			exit
		fi
		;;
		h)
		if [[ "$OPTARG" != "" ]];then
			HBASE_HOME=$OPTARG
		else
			HBASE_HOME=/usr/hdp/current/hbase
		fi
		;;
		i)
		if [[ "$OPTARG" != "" ]];then
			ID=$OPTARG
		else
			print_msg "No peer_id provided."
			exit
		fi
		;;
		V)
		if [[ "$OPTARG" != "" ]];then
			verify_replication $OPTARG
		else
			print_msg "No table provided."
			exit
		fi
		;;
		*)
		print_usage
		;;
	esac
done
	