#!/usr/bin/env bash

{
  l_output="" l_output2=""
  l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"
  a_users=(); a_ulock=() # initialize arrays
  while read -r l_user; do # change system accounts that have a valid login shell to nolog shell
    echo -e " - System account \"$l_user\" has a valid logon shell, changing shell to \"$(which nologin)\""
    usermod -s "$(which nologin)" "$l_user"
  done < <(awk -v pat="$l_valid_shells" -F: '($1!~/(root|sync|shutdown|halt|^\+)/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $(NF) ~ pat) { print $1 }' /etc/passwd)
  while read -r l_ulock; do # Lock system accounts that aren't locked
    echo -e " - System account \"$l_ulock\" is not locked, locking account"
    usermod -L "$l_ulock"
  done < <(awk -v pat="$l_valid_shells" -F: '($1!~/(root|^\+)/ && $2!~/LK?/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $(NF) ~ pat) { print $1 }' /etc/passwd)
}

