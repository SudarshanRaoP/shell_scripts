#!/bin/bash
set -e

print(){
	echo "[+] $*"
}

print_usage(){
	echo -e "Usage: "
	echo -e "\t\thbaseutil.sh [options <args>] <action>"
	echo -e "\t\t\tWhere options are:"
	echo -e "\t\t\t\t-c [<table name>] : Consistency check."
	echo -e "\t\t\t\t-e <table name> : Enable replication on <table name>."
	echo -e "\t\t\t\t-d <table name> : Disable replication on <table name>."

}
check_consistency(){
if [[ `whoami` != "hbase" ]];then
print "This operation can only be performed as 'hbase'."
else
hbase hbck $*
fi
}

enable_replication(){
print "Enabling replication on table : $1"
hbase shell << EOF
enable_table_replication $1
EOF
}

disable_replication(){
print "Disabling replication on table : $1"
hbase shell << EOF
disable_table_replication $1
EOF
}

copy_table(){
	hbase org.apache.hadoop.hbase.mapreduce.CopyTable $*
}

while getopts c::e:d: opts;do
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
		*)
		print_usage
		;;
	esac
done
	