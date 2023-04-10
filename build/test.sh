#!/bin/bash -e


CHECK_FREQUENCY=${CHECK_FREQUENCY:-60}
POSTGRES_CONTAINER_ID=$(docker ps | grep "database_pg-" | awk '{print $1}')


## Check if support regions
#DATABSE_SERVICE_PREFIX=${DATABASE_SERVICE_PREFIX:-"database_pg-"}
#DATABSE_SERVICE_PREFIX="database_pg-"

function get_pg_primary_count () {

	#PG_NODE_COUNT=$(docker exec -it  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep default | grep "primary" | wc -l)
	PG_NODE_COUNT=$(cat cluster_show_dummy | grep default | grep "primary" | wc -l)
	echo $PG_NODE_COUNT
	#unset $PG_NODE_COUNT
}

if [ $(get_pg_primary_count) -gt 1 ]
then

echo "Vale mas 1"

else
  echo "Vale menos de 1"

fi
