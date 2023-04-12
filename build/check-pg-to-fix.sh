#!/bin/bash 

DATA="$1"

function load_expected () {
	
	EXPECTED="$(cat $DATA | grep expected | awk -F " " '{print $13}' | sed 's/"\|)//g')"

	#echo $EXPECTED
}

load_expected

if [ -z "$EXPECTED"  ]
then
	echo "EXPECTED is NULL"
	EXPECTED_2="$(cat $DATA |  grep \!\ running | awk -F "|" '{print $2}' | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')" 
	echo "docker service update database_$EXPECTED_2"
else
	 echo "EXPECTED is not NULL"
	 echo "docker service update database_$EXPECTED"

fi

