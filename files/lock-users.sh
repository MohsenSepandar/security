#!/usr/bin/bash

cat /etc/passwd | while read -r line; do
        USER_NAME=$(echo $line | cut -d ":" -f 1)
        PSTAT=$(passwd -S $USER_NAME | awk {'print $2'})
        if [ $PSTAT != 'P' ]; then
                passwd -l $USER_NAME
        fi
done

