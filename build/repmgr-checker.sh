#!/bin/bash -e
############################
## This repmgr-checker-dummy.sh to test based on $1 input
############################
#Environment variables

VERSION=1.1
CHECK_FREQUENCY=${CHECK_FREQUENCY:-60}
EMAIL_NOTIFICATIONS=${EMAIL_NOTIFICATIONS:-no}
$EMAIL_NOTIFICATIONS_TLS=${$EMAIL_NOTIFICATIONS_TLS:-no}
DATABASE_NAME=${DATABASE_NAME:-database}

# Get the local pg ID

POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')

# Flag to stop script execution

STOP_FIXING="/tmp/stop"

function email_notification_starting () {
# Check if the environment variable is set to "yes"
	if [[ "$EMAIL_NOTIFICATIONS" == "yes" ]]; then
#Check if EMAIL_NOTIFICATIONS_TLS is set to yes
		if [[ "$EMAIL_NOTIFICATIONS_TLS" == "yes" ]]; then
echo "Using TLS authentication for email notifications"
BODY="$(cat <<EOF

REPMGR CHECKER service started for instance $DATABASE_NAME

EOF
)"

	swaks --to "$RECIPIENTS" \
			--from "$SMTP_USER" \
			--header 'Subject: *** SAFEWALK MT - REPMGR-CHECKER STARTING INSTANCE: '$DATABASE_NAME' ***' \
			--body "$BODY" \
			--server "$SMTP_SERVER" \
			--port "$SMTP_PORT" \
			--auth-user "$SMTP_USER" \
			--auth-password "$SMTP_PASSWORD" \
			--tls
		else
echo "Using plain authentication for email notifications"
BODY="$(cat <<EOF

REPMGR CHECKER service started for instance $DATABASE_NAME

EOF
)"

	swaks --to "$RECIPIENTS" \
			--from "$SMTP_USER" \
			--header 'Subject: *** SAFEWALK MT - REPMGR-CHECKER STARTING INSTANCE: '$DATABASE_NAME' ***' \
			--body "$BODY" \
			--server "$SMTP_SERVER" \
			--port "$SMTP_PORT" \
			--auth-user "$SMTP_USER" \
			--auth-password "$SMTP_PASSWORD" \	
		fi

  else
    echo "EMAIL_NOTIFICATIONS environment variable is not set to 'no'. Skipping email send."
  fi


}

function email_notifications () {
 # Check if the environment variable is set to "yes"
  if [[ "$EMAIL_NOTIFICATIONS" == "yes" ]]; then
    # Define the email parameters
    # Use swaks to send the email
	POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')
	CLUSTER_SHOW="$(docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show)"

BODY="$(cat <<EOF

Cluster "${DATABASE_NAME}" fixed at current time - No more attemtps will be performed.

$CLUSTER_SHOW

Check if the ouput shows more than 1 node on "primary" mode if so, please let us now at support@altipeak.com

EOF
)"
	swaks --to "$RECIPIENTS" \
      	      --from "$SMTP_USER" \
      	      --header 'Subject: *** SAFEWALK MT - REPMGR CLUSTER FIX '$DATABASE_NAME' ***' \
              --body "$BODY" \
              --server "$SMTP_SERVER" \
              --port "$SMTP_PORT" \
              --auth-user "$SMTP_USER" \
              --auth-password "$SMTP_PASSWORD" \
              --tls
  else
    echo "EMAIL_NOTIFICATIONS environment variable is not set to 'no'. Skipping email send."
  fi

}

function get_pg_primary_count () {

	POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')
	PG_NODE_COUNT="$(docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | grep default | grep "primary" | grep "running" | wc -l)"
#	PG_NODE_COUNT=$(cat cluster_show_dummy | grep default | grep "primary" | wc -l)
	echo $PG_NODE_COUNT
	# unset $PG_NODE_COUNT
}


function get_pg_to_fix () {

# This function is used to determine the PG server node to be restarted 

	POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')
	PG_TO_FIX="$(docker exec $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | awk -F '|' '$3 == " primary " {print}' | wc -l)"

# IF PG_TO_FIX is NULL it means the repmgr-checker is not running on the same node PG must be fixed

if [ "$PG_TO_FIX" -gt 1  ]

then

# This regular expresion takes the PG server tagged as "! running" which identifies the PG to be fixed

	PG_TO_FIX="$(docker exec $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | awk -F '|' '$3 == " primary " {print}' |  grep '\!\ running' | awk -F "|" '{print $2}' | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')"
	echo $PG_TO_FIX
else

	PG_TO_FIX="$(docker exec $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show | awk -F '|' '$3 == " primary " {print}' | awk -F "|" '{print $2}' | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')"
	echo $PG_TO_FIX
fi

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

    POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')
    docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
    
   # Wait 10 seconds for repmgr cluseter timeouts
    wait_and_check 

	if [ $(get_pg_primary_count) -gt 1 ] 
	then
   		# Print the actual state of the cluster
    		 POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')
		 docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
		 echo "*** REPMGR cluster show before service update ****"
			if [ -f "$STOP_FIXING" ]
			then
				echo "STOPPING FIXING THE CLUSTER ${DATABASE_NAME} TOO MUCH ATTEMPTS **** CALL ALTIPEAK SUPPORT INMEDIATLY!."
			else
				echo "Restarting ${DATABASE_NAME}_$(get_pg_to_fix).... "
				docker service update ${DATABASE_NAME}_$(get_pg_to_fix) --force 
				echo "$(date): Cluster fixed at current time - No more attemtps will be performed." > /tmp/stop
				email_notifications
			fi
		# docker service update database_$(get_pg_to_fix) --force
		
		# Waiting 30 seconds after the restart
		 sleep 30
		 
		 echo "*** REPMGR cluster show after service update ****"
		
   		# Print the state of the cluster after the restart
    		 POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')
		 docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show

	else
	
  		echo "INFO: The number of primary repmgr nodes are ok - do nothing"
	fi

else
	echo "INFO: The number of PG in primary is: $(get_pg_primary_count)  - do nothing"
    	POSTGRES_CONTAINER_ID=$(docker ps | grep "${DATABASE_NAME}_pg-" | awk '{print $1}')
  	docker exec  $POSTGRES_CONTAINER_ID /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf  cluster show
fi
}

# Main program

echo "repmgr-checker version - $VERSION"

### email notification starting the service
email_notification_starting

while : 

do

echo "repmgr-checker version - $VERSION"
monitor_primary_nodes
sleep $CHECK_FREQUENCY

done
