#!/usr/bin/env bash

l_output=""
l_output2=""
a_arr=()
a_suid=()
a_sgid=()

# Populate array with files that will possibly fail one of the audits
while read -r l_mpname; do
  while IFS= read -r -d $'\0' l_file; do
    [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
  done < <(find "$l_mpname" -xdev -not -path "/run/user/*" -type f \( -perm -2000 -o -perm -4000 \) -print0)
done <<< "$(findmnt -Derno target)"

# Test files in the array
while IFS="^" read -r l_fname l_mode; do
  if [ -f "$l_fname" ]; then
    l_suid_mask="04000"
    l_sgid_mask="02000"
    [ $(( $l_mode & $l_suid_mask )) -gt 0 ] && a_suid+=("$l_fname")
    [ $(( $l_mode & $l_sgid_mask )) -gt 0 ] && a_sgid+=("$l_fname")
  fi
done <<< "$(printf '%s\n' "${a_arr[@]}")"

if ! (( ${#a_suid[@]} > 0 )); then
  l_output="There are no SUID files exist on the system"
else
  l_output2="List of \"${#a_suid[@]}\" SUID executable files:\n\n${a_suid[@]}\n\nEnd of list\n"
fi

if ! (( ${#a_sgid[@]} > 0 )); then
  l_output+="\nThere are no SGID files exist on the system"
else
  l_output2+="\nList of \"${#a_sgid[@]}\" SGID executable files:\n\n${a_sgid[@]}\n\nEnd of list\n"
fi

[ -n "$l_output2" ] && l_output2+="\nReview the preceding list(s) of SUID and/or SGID files to\nensure that no rogue programs have been introduced onto the system."

unset a_arr
unset a_suid
unset a_sgid

# If l_output2 is empty, Nothing to report
if [ -z "$l_output2" ]; then
  echo -e "\n- Audit Result:\n$l_output\n"
else
  echo -e "\n- Audit Result:\n$l_output2\n"
  [ -n "$l_output" ] && echo -e "$l_output\n"
fi