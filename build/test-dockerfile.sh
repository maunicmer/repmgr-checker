#!/bin/bash -e


CHECK_FREQUENCY=${CHECK_FREQUENCY:-10}

## Check if support regions
#DATABSE_SERVICE_PREFIX=${DATABASE_SERVICE_PREFIX:-"database_pg-"}
#DATABSE_SERVICE_PREFIX="database_pg-"

function get_pg_primary_count () {

	#PG_NODE_COUNT=$(docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep default | grep "primary" | wc -l)
	PG_NODE_COUNT=$(cat cluster_show_dummy | grep default | grep "primary" | wc -l)
	echo $PG_NODE_COUNT
	# unset $PG_NODE_COUNT
}

function get_pg_to_fix (){

	#PG_TO_FIX=$(docker exec $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep \*\ running | grep -v running\ as\ primary | awk -F '|' '{print $2}')
	PG_TO_FIX=$(cat cluster_show_dummy | grep default | grep \*\ running | grep -v running\ as\ primary | awk -F '|' '{print $2}' | sed 's/ //g')
	echo $PG_TO_FIX
}		
while :

do


ITERATION_COUNT=0

  function wait_and_check () {

	while [ ${ITERATION_COUNT} -lt 5 ]; 
	do

		#PG_NODE_COUNT=$(cat /usr/local/bin/cluster_show_dummy)

		if [ $(get_pg_primary_count) -gt 1 ]
			then
  				ITERATION_COUNT=$((ITERATION_COUNT + 1))
				## PG_NODE_COUNT as function
				#PG_NODE_COUNT=get_pg_primary_count
				#PG_NODE_COUNT=$(docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep "primary" | wc -l)
				echo "Iteration - $ITERATION_COUNT"
				echo "Node count - $(get_pg_primary_count)"
  				sleep 3

			else
			break
			fi
	done

  }
# Get the local pg ID

POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')

#PG_NODE_COUNT=$(cat /usr/local/bin/cluster_show_dummy)

## Check if this only match with table values

#PG_NODE_COUNT=$(docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep "primary" | wc -l)

#PG_NODE_COUNT=get_pg_primary_count

#PG_TO_FIX=pg-0
#PG_TO_FIX=$(docker exec $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep \*\ running | grep -v running\ as\ primary | awk -F '|' '{print $2}')


if [ $(get_pg_primary_count) -gt 1 ]
then
    
    # echo "Warning: More than 1 primary nodes detected!"
    #logger -p local0.notice -t "SAFEWALK REPMGR MONITOR" "****** MORE THAN 1 DATABASE NODE IN PRIMARY MODE ******"
    
    echo "SAFEWALK REPMGR MONITOR ****** MORE THAN 1 DATABASE NODE IN PRIMARY MODE ******"
    
    docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
    
    # Wait 10 seconds for repmgr cluseter timeouts
    wait_and_check 

	if [ $(get_pg_primary_count) -gt 1 ] 
	then
		docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
		echo "*** REPMGR cluster show before service update ****"
                # PG_TO_FIX=$(docker exec $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep \*\ running | grep -v running\ as\ primary | awk -F '|' '{print $2}')
		echo "docker service update database_$(get_pg_to_fix) --force"
		sleep 30
		echo "*** REPMGR cluster show after service update ****"
		docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show

	else
	
  		echo "INFO: The number of primary repmgr nodes are ok - do nothing"
	fi

else
  echo "INFO: The number of PG in primary is: $PG_NODE_COUNT  - do nothing"
  docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
fi

#sleep 60
sleep $CHECK_FREQUENCY
done
