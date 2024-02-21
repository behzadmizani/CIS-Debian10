#!/usr/bin/env bash

l_output=""
l_output2=""
a_path=()
a_arr=()
a_nouser=()
a_nogroup=()

# Initialize arrays
a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*")

while read -r l_bfs; do
  a_path+=( -a ! -path "$l_bfs/*" )
done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/ {print $2}')

while IFS= read -r -d $'\0' l_file; do
  [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%U^%G' "$l_file")") && echo "Adding: $l_file"
done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2> /dev/null)

while IFS="^" read -r l_fname l_user l_group; do
  # Test files in the array
  [ "$l_user" = "UNKNOWN" ] && a_nouser+=("$l_fname")
  [ "$l_group" = "UNKNOWN" ] && a_nogroup+=("$l_fname")
done <<< "$(printf '%s\n' "${a_arr[@]}")"

if ! (( ${#a_nouser[@]} > 0 )); then
  l_output="No unowned files or directories exist on the local filesystem."
else
  l_output2="There are \"${#a_nouser[@]}\" unowned files or directories on the system.\n\nThe following is a list of unowned files and/or directories:\n\n${a_nouser[@]}\n\nEnd of list."
fi

if ! (( ${#a_nogroup[@]} > 0 )); then
  l_output+="\nNo ungrouped files or directories exist on the local filesystem."
else
  l_output2+="\n\nThere are \"${#a_nogroup[@]}\" ungrouped files or directories on the system.\n\nThe following is a list of ungrouped files and/or directories:\n\n${a_nogroup[@]}\n\nEnd of list."
fi

unset a_path
unset a_arr
unset a_nouser
unset a_nogroup

if [ -z "$l_output2" ]; then
  # If l_output2 is empty, we pass
  echo -e "\n- Audit Result:\n ** PASS **\n\n- * Correctly configured * :\n\n$l_output\n"
else
  echo -e "\n- Audit Result:\n ** FAIL **\n\n- * Reasons for audit failure * :\n\n$l_output2"
  [ -n "$l_output" ] && echo -e "\n- * Correctly configured * :\n\n$l_output\n"
fi