#!/bin/bash

# Using file paths.txt to store output of 'find' which prints all perms in octal and rwx format
# Then running egrep on the paths.txt file to filter via RegEx and filtering output >> permissions.txt
print_write_func(){
        echo "-----------------------------------------------------------------" > $HOME/permissions.txt
        echo "#                    Write Perms in Usr/Grp                      #" >> $HOME/permissions.txt
        echo "-----------------------------------------------------------------" >> $HOME/permissions.txt
        echo -e 'Oct\tPerm\t\tUser\tGrp\t\tPath' >> $HOME/permissions.txt
        echo -e '---\t----\t\t----\t---\t\t----' >> $HOME/permissions.txt
        find "$1" -printf '%m\t%M\t%u\t%g\t%p\n' >> $HOME/paths.txt
        #Look for write permissions in the 2nd or 3rd digit of the Octal -rwx- perms
        egrep '^[0-7][2367][0-7]|^[0-7][0-7][2367]' $HOME/paths.txt >> $HOME/permissions.txt
}

# On standard RHEL DLP install we have 3 perms:
#       1. Directories are 755
#       2. Generic Files are 750
#       3. Encryption and SSLKeystores are 644
# This function will locate and display all non 755,750, and 644 perms
print_non_std_perms(){
        echo "-----------------------------------------------------------------" > $HOME/non_std_perms.txt
        echo "#                     Non Std Permissions                       #" >> $HOME/non_std_perms.txt
        echo "-----------------------------------------------------------------" >> $HOME/non_std_perms.txt
        grep -v '664\|644\|755\|750' $HOME/paths.txt >> $HOME/non_std_perms.txt
}

modify_perms(){
        declare -a permArray
        declare -i ELEMENTS

        permArray=(`grep -v '664\|644\|755\|750' paths.txt | sed 's/ //g'`)
        ELEMENTS="${#permArray[@]}"

        for ((i=0;i<ELEMENTS;i=i+5)) {
                echo "Element [$i]: ${permArray[$i]} : ${permArray[$i+1]} : ${permArray[$i+4]}"
                #Check first letter of extended rwx perms to determine if file is symlink, dir, or file
                #Directories
                MOD_PATH=${permArray[$i+4]}
                if [[ ${permArray[$i+4]} == *"15.1"* ]]; then
                        MOD_PATH=${MOD_PATH/EnforceServer/Enforce Server}
                fi
                if [[ ${permArray[$i+1]} == d* ]]; then
                        echo "Modifying directory: $MOD_PATH"
                        chmod 755 "$MOD_PATH"
                #Log files use 664 perms
                elif [[ ${permArray[$i+1]} == -* ]] && [[ ${permArray[$i+4]} =~ .+\.log?[\.]?[\d]?.+ || ${permArray[$i+4]} =~ localhost.*\.txt ]]; then
                        echo "Modifying log: $MOD_PATH"
                        chmod 664 "$MOD_PATH"
                #Need extra perms to determine if file is secure file that needs 644 rather than 750
                elif [[ ${permArray[$i+1]} == -* ]] && [[ ${permArray[$i+4]} != *.key || ${permArray[$i+4]} != *.sslKeyStore ]]; then
                        echo "Modifying file: $MOD_PATH"
                        chmod 750 "$MOD_PATH"
                #sslKeystore, .key, and other security files require 644 permissions.
                elif [[ ${permArray[$i+1]} == -* ]] && [[ ${permArray[$i+4]} == *.key || ${permArray[$i+4]} == *.sslKeyStore ]]; then
                        echo "Modifying security file: $MOD_PATH"
                        chmod 644 "$MOD_PATH"
                else
                        echo "Unable to determine file type : $MOD_PATH"
                fi
        }
}

#Function Calls
print_write_func "$1"
print_non_std_perms
echo -n "Modify non standard perms? [y]es [n]o: "
read PERM_CALL

if [[ $PERM_CALL == y ]]; then
        modify_perms
elif [[ $PERM_CALL != y ]]; then
        echo "No modifications made"
else
        echo "Invalid entry"
fi

#In the end, sub $HOME for /tmp or something or take a switch value for an output location and send
#       results to this location.
#cat $HOME/permissions.txt
#cat $HOME/non_std_perms.txt
rm -f $HOME/paths.txt
