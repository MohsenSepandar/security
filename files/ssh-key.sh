#!/usr/bin/env bash

{
  l_output="" l_output2=""
  l_skgn="ssh_keys" # Group designated to own openSSH keys
  l_skgid="$(awk -F: '($1 == "'"$l_skgn"'"){print $3}' /etc/group)" # Get gid of group
  if [ -n "$l_skgid" ]; then
    l_agroup="(root|$l_skgn)" && l_sgroup="$l_skgn" && l_mfix="u-x,g-wx,o-rwx"
  else
    l_agroup="root" && l_sgroup="root" && l_mfix="u-x,go-rwx"
  fi
  unset a_skarr && a_skarr=() # Clear and initialize array
  while IFS= read -r -d $'\0' l_file; do # Loop to populate array
    if grep -Pq ':\h+OpenSSH\h+private\h+key\b' <<< "$(file "$l_file")"; then
        a_skarr+=("$(stat -Lc '%n^%#a^%U^%G^%g' "$l_file")")
      fi
    done < <(find -L /etc/ssh -xdev -type f -print0)
    while IFS="^" read -r l_file l_mode l_owner l_group l_gid; do
      l_out2=""
      [ "$l_gid" = "$l_skgid" ] && l_pmask="0137" || l_pmask="0177"
      l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"
      if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
        l_out2="$l_out2\n - Mode: \"$l_mode\" should be mode: \"$l_maxperm\" or more restrictive\n - Revoking excess permissions"
        chmod "$l_mfix" "$l_file"
      fi
      if [ "$l_owner" != "root" ]; then
        l_out2="$l_out2\n - Owned by: \"$l_owner\" should be owned by \"root\"\n - Changing ownership to \"root\""
        chown root "$l_file"
      fi
      if [[ ! "$l_group" =~ $l_agroup ]]; then
        l_out2="$l_out2\n - Owned by group \"$l_group\" should be group owned by: \"${l_agroup//|/ or }\"\n - Changing group ownership to \"$l_sgroup\""
        chgrp "$l_sgroup" "$l_file"
      fi
      [ -n "$l_out2" ] && l_output2="$l_output2\n - File: \"$l_file\"$l_out2"
    done <<< "$(printf '%s\n' "${a_skarr[@]}")"
    unset a_skarr
    if [ -z "$l_output2" ]; then
      echo -e "\n- No access changes required\n"
    else
      echo -e "\n- Remediation results:\n$l_output2\n"
    fi
  }

