#!/usr/bin/env bash

l_output=""
l_output2=""
l_smask='01000'
a_path=()
a_arr=()
a_file=()
a_dir=()

# Initialize arrays
a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "/sys/kernel/security/apparmor/*" -a ! -path "/snap/*" -a ! -path "/sys/fs/cgroup/memory/*")

while read -r l_bfs; do
  a_path+=( -a ! -path "$l_bfs/*" )
done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/ {print $2}')

# Populate array with files that will possibly fail one of the audits
while IFS= read -r -d $'\0' l_file; do
  [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)

while IFS="^" read -r l_fname l_mode; do
  # Test files in the array
  [ -f "$l_fname" ] && a_file+=("$l_fname")

  # Add WR files
  if [ -d "$l_fname" ]; then
    # Add directories w/o sticky bit
    [ ! $(( $l_mode & $l_smask )) -gt 0 ] && a_dir+=("$l_fname")
  fi
done < <(printf '%s\n' "${a_arr[@]}")

if ! (( ${#a_file[@]} > 0 )); then
  l_output="No world-writable files exist on the local filesystem."
else
  l_output2="There are \"${#a_file[@]}\" world-writable files on the system.\n\nThe following is a list of world-writable files:\n\n${a_file[@]}\n\nEnd of list."
fi

if ! (( ${#a_dir[@]} > 0 )); then
  l_output+="\nSticky bit is set on world-writable directories on the local filesystem."
else
  l_output2+="\n\nThere are \"${#a_dir[@]}\" world-writable directories without the sticky bit on the system.\n\nThe following is a list of world-writable directories without the sticky bit:\n\n${a_dir[@]}\n\nEnd of list."
fi

unset a_path
unset a_arr
unset a_file
unset a_dir

# If l_output2 is empty, we pass
if [ -z "$l_output2" ]; then
  echo -e "\n- Audit Result:\n ** PASS **\n\n- * Correctly configured * :\n\n$l_output\n"
else
  echo -e "\n- Audit Result:\n ** FAIL **\n\n- * Reasons for audit failure * :\n\n$l_output2"
  [ -n "$l_output" ] && echo -e "\n- * Correctly configured * :\n\n$l_output\n"
fi