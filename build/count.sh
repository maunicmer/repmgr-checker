#!/bin/bash

# Replace "filename" with the path to your file
count=$(cat $1 | awk -F '|' '$3 == " primary " {print}' | wc -l)

if [ "$count" -gt 1 ]
then
    # Do something here if the count is greater than 2
    cat $1 | awk -F '|' '$3 == " primary " {print}' |  grep '\!\ running' | awk -F "|" '{print $2}' | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'
else
    cat $1 | awk -F '|' '$3 == " primary " {print}' | awk -F "|" '{print $2}' | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'
fi
