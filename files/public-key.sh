#!/usr/bin/env bash

{
  l_pmask="0133"
  l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"
  awk '{print}' <<< "$(find -L /etc/ssh -xdev -type f -exec stat -Lc "%n %#a %U %G" {} +)" | (while read -r l_file l_mode l_owner l_group; do
        if file "$l_file" | grep -Pq ':\h+OpenSSH\h+(\H+\h+)?public\h+key\b'; then
          echo -e " - Checking private key file: \"$l_file\""
          if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
            echo -e " - File: \"$l_file\" is mode \"$l_mode\" changing to mode: \"$l_maxperm\""
            chmod u-x,go-wx "$l_file"
          fi
          if [ "$l_owner" != "root" ]; then
            echo -e " - File: \"$l_file\" is owned by: \"$l_owner\" changing owner to \"root\""
            chown root "$l_file"
          fi
          if [ "$l_group" != "root" ]; then
            echo -e " - File: \"$l_file\" is owned by group \"$l_group\" changing to group \"root\""
            chgrp "root" "$l_file"
          fi
        fi
      done
    )
  }

