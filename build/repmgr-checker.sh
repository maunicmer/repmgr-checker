#!/bin/bash -e

#Environment variables

CHECK_FREQUENCY=${CHECK_FREQUENCY:-60}

# Get the local pg ID

POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')

# Flag to stop script execution

STOP_FIXING="/tmp/stop"

function get_pg_primary_count () {

	POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')
	PG_NODE_COUNT="$(docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep default | grep "primary" | grep "running" | wc -l)"
#	PG_NODE_COUNT=$(cat cluster_show_dummy | grep default | grep "primary" | wc -l)
	echo $PG_NODE_COUNT
	# unset $PG_NODE_COUNT
}

function get_pg_to_fix (){

	POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')
	PG_TO_FIX="$(docker exec $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep \*\ running | grep -v running\ as\ primary | awk -F '|' '{print $2}')"
#	PG_TO_FIX=$(cat cluster_show_dummy | grep default | grep \*\ running | grep -v running\ as\ primary | awk -F '|' '{print $2}' | sed 's/ //g')
	echo $PG_TO_FIX
}


function wait_and_check () {

ITERATION_COUNT=0
	while [ ${ITERATION_COUNT} -lt 6 ]; 
	do

		#PG_NODE_COUNT=$(cat /usr/local/bin/cluster_show_dummy)

		if [ $(get_pg_primary_count) -gt 1 ]
			then
  				ITERATION_COUNT=$((ITERATION_COUNT + 1))
				echo "Iteration - $ITERATION_COUNT"
				echo "Node count - $(get_pg_primary_count)"
  				sleep 10

			else
			break
			fi
	done

}

# Monitor if postgres primary nodes are greater than 1
function monitor_primary_nodes() {
if [ $(get_pg_primary_count) -gt 1 ]

then    
   # Loggin if true 

    echo "SAFEWALK REPMGR MONITOR ****** MORE THAN 1 DATABASE NODE IN PRIMARY MODE ******"
   # Print the actual state of the cluster

    POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')
    docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
    
   # Wait 10 seconds for repmgr cluseter timeouts
    wait_and_check 

	if [ $(get_pg_primary_count) -gt 1 ] 
	then
   		# Print the actual state of the cluster
    		 POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')
		 docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
		 echo "*** REPMGR cluster show before service update ****"
			if [ -f "$STOP_FIXING" ]
			then
				echo "STOPPING FIXING THE CLUSTER TOO MUCH ATTEMPTS **** CALL ALTIPEAK SUPPORT INMEDIATLY!."
			else
				docker service update database_$(get_pg_to_fix) --force 
				echo "$(date): Cluster fixed at current time - No more attemtps will be performed." > /tmp/stop
			fi
		# docker service update database_$(get_pg_to_fix) --force
		
		# Waiting 30 seconds after the restart
		 sleep 30
		 
		 echo "*** REPMGR cluster show after service update ****"
		
   		# Print the state of the cluster after the restart
    		 POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')
		 docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show

	else
	
  		echo "INFO: The number of primary repmgr nodes are ok - do nothing"
	fi

else
	echo "INFO: The number of PG in primary is: $(get_pg_primary_count)  - do nothing"
    	POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')
  	docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
fi
}

# Main program

while : 

do

monitor_primary_nodes
sleep $CHECK_FREQUENCY

done
