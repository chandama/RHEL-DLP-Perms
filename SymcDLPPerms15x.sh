#!/bin/bash

# Written by: Chandler Taylor
# Date: November 19, 2019
#
# TODO: Add switch to keep output files as 'log' files, if not, discard 'permissions.txt' and 'non_std_perms.txt'


# Having write permissions anywhere except the ownership octal is a security risk
# Using file 'paths.txt' to store output of 'find' which prints all perms in octal and -rwx- format
# Then running 'egrep' on the 'paths.txt' to filter via RegEx and filtering output >> 'permissions.txt'
print_write_func(){

        find "$1" -printf '%m\t%M\t%u\t%g\t%p\n' >> $HOME/paths.txt
        echo "-----------------------------------------------------------------" > $HOME/permissions.txt
        echo "#                    Write Perms in Usr/Grp                      #" >> $HOME/permissions.txt
        echo "-----------------------------------------------------------------" >> $HOME/permissions.txt
        echo -e 'Oct\tPerm\t\tUser\tGrp\t\tPath' >> $HOME/permissions.txt
        echo -e '---\t----\t\t----\t---\t\t----' >> $HOME/permissions.txt
        #Look for write permissions in the 2nd or 3rd digit of the Octal -rwx- perms
        egrep '^[0-7][2367][0-7]|^[0-7][0-7][2367]' $HOME/paths.txt >> $HOME/permissions.txt

}

# On standard RHEL DLP install we have 4 perms:
#       1. Directories are 755
#       2. Generic files are 750
#       3. Encryption files and SSLKeystore files are 644
#       4. Log files are 664
# This function will locate and display all non 755, 750, 664, and 644 perms
print_non_std_perms(){

        find "$1" -printf '%m\t%M\t%u\t%g\t%p\n' >> $HOME/paths.txt
        echo "-----------------------------------------------------------------" > $HOME/non_std_perms.txt
        echo "#                     Non Std Permissions                       #" >> $HOME/non_std_perms.txt
        echo "-----------------------------------------------------------------" >> $HOME/non_std_perms.txt
        grep -v '664\|644\|755\|750' $HOME/paths.txt >> $HOME/non_std_perms.txt

}

# Take 
modify_perms(){

        declare -a permArray
        declare -i ELEMENTS

        permArray=(`grep -v '664\|644\|755\|750' paths.txt | sed 's/ //g'`)
        ELEMENTS="${#permArray[@]}"

        for ((i=0;i<ELEMENTS;i=i+5)) {
                #echo "Element [$i]: ${permArray[$i]} : ${permArray[$i+1]} : ${permArray[$i+4]}"
                #Check first letter of extended -rwxrwxrwx perms to determine if file is symlink, dir, or file
                #       d = directory
                #       - = standard file
                MOD_PATH=${permArray[$i+4]}
                if [[ ${permArray[$i+4]} == *"15.1"* ]]; then
                        MOD_PATH=${MOD_PATH/EnforceServer/Enforce Server}
                fi
                if [[ ${permArray[$i+1]} == d* ]]; then
                        echo "Modifying directory: $MOD_PATH"
                        chmod 755 "$MOD_PATH"
                #Log files use 664 perms (RegEx captures files ending in .log, .lck, .log.n and .log.n.lck)
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

echo "
#####################################################################################
#                                                                                   #
#          This script is only intended for use with Symantec DLP 15.x              #
#      Do not use this script on any directory other than the SymantecDLP 15.x      #
#  installation directories or else system permissions may be altered incorrectly.  #
#                                                                                   #
#      THIS SCRIPT IS NOT LICENSED OR ENDORSED BY SYMANTEC USE AT YOUR OWN RISK     #
#                                                                                   #
#####################################################################################

Please make a selection:
1: View incorrect write permissions 
2: View non-standard permissions
3: Modify non-standard permissions to default"
read selection

case $selection in
        1)
                print_write_func "$1"
                cat $HOME/permissions.txt
                rm -f $HOME/paths.txt
                ;;
        2)
                print_non_std_perms "$1"
                cat $HOME/non_std_perms.txt
                rm -f $HOME/paths.txt
                ;;
        3)
                echo -n "Modify non standard perms? [y]es [n]o: "
                read prompt
                if [[ $prompt == y ]]; then
                        print_write_func "$1"
                        modify_perms
                        rm -f $HOME/paths.txt
                elif [[ $PERM_CALL == n ]]; then
                        echo "No modifications made"
                else
                        echo "Invalid entry"
                fi
                ;;
        *)
                echo "Invalid entry"
                ;;
esac
