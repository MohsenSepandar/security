#!/bin/bash

cat /etc/passwd | while read -r line; do 
	USER_ID=$(echo $line | cut -d : -f 3);
	USER_NAME=$(echo $line | cut -d : -f 1)
	if [[ $USER_ID -gt 1000 && $USER_ID -le 65530 ]];then
		chage --mindays 1 $USER_NAME
		chage --maxdays 365 $USER_NAME
		chage --warndays 7 $USER_NAME
		chage --inactive 30 $USER_NAME
	fi
done
