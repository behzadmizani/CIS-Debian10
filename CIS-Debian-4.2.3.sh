#!/usr/bin/env bash
{
    l_output=""
    l_output2=""
    l_pmask="0133"
    
    # Find public key files and retrieve their information using stat
    awk '{print}' <<< "$(find -L /etc/ssh -xdev -type f -exec stat -Lc "%n %#a %U %G" {} +)" |
    
    (
        while read -r l_file l_mode l_owner l_group; do
            # Check if the file is a public key file
            if file "$l_file" | grep -Pq ':\h+OpenSSH\h+(\H+\h+)?public\h+key\b'; then
                l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"
                
                # Check if the mode is more permissive than the maximum permissible mode
                if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
                    l_output2="$l_output2\n - Public key file: \"$l_file\" is mode \"$l_mode\" should be mode: \"$l_maxperm\" or more restrictive"
                else
                    l_output="$l_output\n - Public key file: \"$l_file\" is mode \"$l_mode\" should be mode: \"$l_maxperm\" or more restrictive"
                fi
                
                # Check if the owner is not "root"
                if [ "$l_owner" != "root" ]; then
                    l_output2="$l_output2\n - Public key file: \"$l_file\" is owned by: \"$l_owner\" should be owned by \"root\""
                else
                    l_output="$l_output\n - Public key file: \"$l_file\" is owned by: \"$l_owner\" should be owned by \"root\""
                fi
                
                # Check if the group is not "root"
                if [ "$l_group" != "root" ]; then
                    l_output2="$l_output2\n - Public key file: \"$l_file\" is owned by group \"$l_group\" should belong to group \"root\"\n"
                else
                    l_output="$l_output\n - Public key file: \"$l_file\" is owned by group \"$l_group\" should belong to group \"root\"\n"
                fi
            fi
        done
        
        # Print the audit result
        if [ -z "$l_output2" ]; then
            echo -e "\n- Audit Result:\n *** PASS ***\n$l_output"
        else
            echo -e "\n- Audit Result:\n *** FAIL ***\n$l_output2\n\n - Correctly set:\n$l_output"
        fi
    )
}