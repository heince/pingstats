#!/bin/bash

host=$1

if [ -z $host ]; then
    echo "Usage: `basename $0` [HOST]"
    exit 1
fi

output=$host"_ping_output.txt"

while :; do
    result=`ping -W 1 -c 1 $host | grep 'bytes from '`
    if [ $? -gt 0 ]; then
        echo "`date +'%Y/%m/%d %H:%M:%S'` - host $host is down" >> $output
    else
        echo "`date +'%Y/%m/%d %H:%M:%S'` - host $host is ok -`echo $result | cut -d ':' -f 2`" >> $output
        sleep 1 # avoid ping rain
    fi
done
