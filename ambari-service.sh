#!/bin/bash

print(){
	echo "[+] $*"
}

print_usage(){
	echo -e "Usage: "
	echo -e "\t\tambari-service.sh [options <args>] <action>"
	echo -e "\t\t\tWhere options are:"
	echo -e "\t\t\t\t-u <username> : Ambari username."
	echo -e "\t\t\t\t-p <password> : Ambari password."
	echo -e "\t\t\t\t-a <ambari host> : Ambari server hostname."
	echo -e "\t\t\t\t-c <cluster name> : Cluster name."
	echo -e "\t\t\t\t-s <service name> : Service name."
	echo -e "\t\t\t\t-h <host> : Host-ID, typically same as hostname."
	echo -e "\t\t\t\t-r <role name> : Role or component name.\n"
	echo -e "\t\t\tWhere actions are:"
	echo -e "\t\t\t\t-g : Get service information."
	echo -e "\t\t\t\t-x : Stop a service."
	echo -e "\t\t\t\t-d : Delete a service."
}

get_service_info(){
	#getting node information
	#curl -u admin:admin -H "X-Requested-By: ambari" -X GET  http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICENAME
	curl -u $1:$2 -H "X-Requested-By: ambari" -X GET  http://$3:8080/api/v1/clusters/$4/services/$5
}

stop_service(){
	#Ensure service is stopped
	#curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop Service"},"Body":{"ServiceInfo":{"state":"INSTALLED"}}}' http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICE_NAME
	curl -u $1:$2 -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop Service"},"Body":{"ServiceInfo":{"state":"INSTALLED"}}}' http://$3:8080/api/v1/clusters/$4/services/$5
}

stop_component(){
	#Stop a perticular component
	#curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop Component"},"Body":{"HostRoles":{"state":"INSTALLED"}}}' http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/hosts/HOSTNAME/host_components/COMPONENT_NAME
	curl -u $1:$2 -H "X-Requested-By: ambari" -X PUT -d '{"HostRoles": {"state": "MAINTENANCE"}}' http://$3:8080/api/v1/clusters/$4/hosts/$5/host_components/$6
}

stop_all_components(){
	#Stop all component instances
	#curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop All Components"},"Body":{"ServiceComponentInfo":{"state":"INSTALLED"}}}' http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICE_NAME/components/COMPONENT_NAME
	curl -u $1:$2 -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop All Components"},"Body":{"ServiceComponentInfo":{"state":"INSTALLED"}}}' http://$3:8080/api/v1/clusters/$4/services/$5/components/$6
}

delete_service(){
	#Delete service
	#curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICENAME
	curl -u $1:$2 -H "X-Requested-By: ambari" -X DELETE  http://$3:8080/api/v1/clusters/$4/services/$5
}

while getopts gdu:p:a:c:s:h:r:x opts;do
	case $opts in
		u)
		if [[ "$OPTARG" != "" ]]; then
			user=$OPTARG
		else
			user='admin'
		fi;;
		p)
		if [[ "$OPTARG" != "" ]]; then
			password=$OPTARG
		else
			password='admin'
		fi;;
		a)
		if [[ "$OPTARG" != ""G ]]; then
			ambari=$OPTARG
		else
			ambari="localhost"
		fi;;
		c)
		if [[ "$OPTARG" != "" ]]; then
			cluster=$OPTARG
		else
			print Error: Cluster name is missing.
			exit 1
		fi;;
		s)
		if [[ "$OPTARG" != "" ]]; then
			service=$OPTARG
		else
			print Error: Service name is missing.
			exit 1
		fi;;
		h)
		if [[ "$OPTARG" != "" ]]; then
			host=$OPTARG
		else
			host='localhost'
		fi;;
		r)
		if [[ "$OPTARG" != "" ]]; then
			role=$OPTARG
		else
			print Error: Role name is missing.
		fi;;
		g)
		print Getting service info
		get_service_info $user $password $ambari $cluster $service
		;;
		x)
		print Stopping $service service
		stop_service $user $password $ambari $cluster $service
		print Stopping all $service components
		stop_all_components $user $password $ambari $cluster $service
		;;
		d)
		print Deleting $service service
		delete_service $user $password $ambari $cluster $service
		;;
		*)
		print_usage
		;;
	esac
done
