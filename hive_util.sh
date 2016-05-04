#!/bin/bash

print_msg(){
	echo "[+] $*"
}

print_usage(){
	echo -e "Usage: "
	echo -e "\t\thive_util.sh [options <args>] <action>"
	echo -e "\t\t\tWhere options are:"
	echo -e "\t\t\t\t-t <table> : Table name.E.g. database.table"
	echo -e "\t\t\t\t-p <directory path> : E.g. /tmp/hive-data"
	echo -e "\t\t\t\t-s <source> : Source HDFS path. E.g. hdfs://srcname:8020/tmp/src/data"
	echo -e "\t\t\t\t-d <destination> : Destination HDFS path. E.g. hdfs://destname:8020/tmp/dest/data"
  	echo -e "\t\t\tWhere action is:"
  	echo -e "\t\t\t\t-i : Import data to Hive Table"
  	echo -e "Example:"
  	echo -e "\t\thive_util.sh -t somedb.sometbl -p /tmp/hive/import -i"
  	echo
  	echo -e "\t\t\t\t-e : Export data FROM Hive Table"
  	echo -e "Example:"
  	echo -e "\t\thive_util.sh -t somedb.sometbl -p /tmp/hive/export -e"
  	echo
  	echo -e "\t\t\t\t-c : Copy data"
  	echo -e "Example:"
  	echo -e "\t\thive_util.sh -s hdfs://src.cluster:8020/src/data -d hdfs://dest.cluster:8020/dest/data -c"
}

import_data(){
print_msg Importing data from $2 into $1
hive <<EOF
IMPORT TABLE $1 FROM '$2';
EOF
}

export_data(){
print_msg Export data from $1 to $2
hive <<EOF
EXPORT TABLE $1 TO '$2';
EOF
}

copy_data(){
print_msg Copying data from $1 to $2
hadoop distcp $1 $2
}

while getopts t:p:s:d:iec opts; do
    case $opts in
    	t)
		if [[ $OPTARG == "" ]];then
			print_msg Table argument is missing.
			print_usage
			exit
		else
			TABLE=$OPTARG
		fi
		;;
		p)
		if [[ $OPTARG == "" ]];then
			rint_msg Directory path argument is missing.
			print_usage
			exit
		else
			DIR=$OPTARG
		fi
		;;
		s)
		if [[ $OPTARG == "" ]];then
			rint_msg Source argument is missing.
			print_usage
			exit
		else
			SRC=$OPTARG
		fi
		;;
		d)
		if [[ $OPTARG == "" ]];then
			rint_msg Destination argument is missing.
			print_usage
			exit
		else
			DEST=$OPTARG
		fi
		;;
		i)
		import_data $TABLE $DIR
		;;
		e)
		export_data $TABLE $DIR
		;;
		c)
		copy_data $SRC $DEST
		;;
		*)
		print_usage
		;;
	esac
done