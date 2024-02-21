#!/bin/bash

cut -f3 -d":" /etc/passwd | sort -n | uniq -c | while read -r count uid; do
    if [ "$count" -gt 1 ]; then
        users=$(awk -F: -v n="$uid" '($3 == n) { print $1 }' /etc/passwd | xargs)
        echo "Duplicate UID ($uid): $users"
    fi
done