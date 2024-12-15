#!/usr/bin/env bash

{
 l_smask='01000'
 a_path=(); a_arr=() # Initialize array
 a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "/sys/kernel/security/apparmor/*" -a ! -path "/snap/*" -a ! -path "/sys/fs/cgroup/memory/*")
 while read -r l_bfs; do
 a_path+=( -a ! -path ""$l_bfs"/*")
 done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/ {print $2}')
 # Populate array with files
 while IFS= read -r -d $'\0' l_file; do
 [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
 done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)
 while IFS="^" read -r l_fname l_mode; do # Test files in the array
 if [ -f "$l_fname" ]; then # Remove excess permissions from WW files
 echo -e " - File: \"$l_fname\" is mode: \"$l_mode\"\n - removing write permission on \"$l_fname\" from \"other\""
 chmod o-w "$l_fname"
 fi
 if [ -d "$l_fname" ]; then
 if [ ! $(( $l_mode & $l_smask )) -gt 0 ]; then # Add sticky bit
 echo -e " - Directory: \"$l_fname\" is mode: \"$l_mode\" and doesn't have the sticky bit set\n - Adding the sticky bit"
 chmod a+t "$l_fname"
 fi
 fi
 done < <(printf '%s\n' "${a_arr[@]}")
 unset a_path; unset a_arr # Remove array
}
