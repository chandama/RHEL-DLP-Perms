#!/bin/bash


#TODO
#When thinking about modifying perms and ownership, realize that DLP is installed /opt /var and /spool
#So all perms must be changed simultaneously or there can be issues.

########################################################################
#                       Jason's Comments:
# Set default paths as variables at the top, so its easy to quickly change (/opt, /var, /spool)
# Query service or file for a user, set that as the default user, then prompt the user to enter
#       the protect usernamed or hit enter to use the username automatically identified.
# Set default behavior to simply record bad areas, give option to make changes (via uncommenting code).
########################################################################


#Default Path Values

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
        grep -v '644\|755\|750' $HOME/paths.txt >> $HOME/non_std_perms.txt
}

modify_perms(){
        declare -a permArray
        #Use sed to remove spaces but keep tab separators in paths.txt
        #Use grep with pattern or possibly cat and then grep later to identify suspect files.
        permArray=(`grep -v '644\|755\|750' paths.txt | sed 's/ //g'`)
        declare -i ELEMENTS
        ELEMENTS="${#permArray[@]}"
        for ((i=0;i<ELEMENTS;i=i+5)) {
                echo "Element [$i]: ${permArray[$i]} : ${permArray[$i+1]} : ${permArray[$i+4]}"
                #Check first letter of extended rwx perms to determine if file is symlink, dir, or file
                #Directories

                #Need to edit the path element $i+4 to contain space if in 15.1 for chmod to run
                #If script is goign to run on all 15.x versions, you need to check for 15.1 in the path
                # and then modify 'EnforceServer' to 'Enforce\ Server' or leave it
                # Check MOD_PATH for 15.5 or 15.1 and only add space if 15.1 is found in MOD_PATH
                MOD_PATH=${permArray[$i+4]}
                if [[ ${permArray[$i+1]} == d* ]]; then
                        echo "Modifying dir permissions: ${permArray[$i+4]}"
                        chmod 755 MOD_PATH
                #Files
                #Need extra perms to determine if file is secure file that needs 644 rather than 750
                elif [[ ${permArray[$i+1]} == -* ]] && [[ ${permArray[$i+4]} != *.key || ${permArray[$i+4]} != *.sslKeyStore ]]; then
                        echo "Modifying file permissions: ${permArray[$i+4]}"
                        chmod 750 MOD_PATH
                #sslKaystore, .key, and other security files require 644 permissions.
                elif [[ ${permArray[$i+1]} == -* ]] && [[ ${permArray[$i+4]} == *.key || ${permArray[$i+4]} == *.sslKeyStore ]]; then
                        echo "Modifying security file permissions: ${permArray[$i+4]}"
                        chmod 644 MOD_PATH
                else
                        echo "File type undetermined : ${permArray[$i+4]}"
                fi
        }
}

#Call Functions
print_write_func "$1"
print_non_std_perms
echo "Modify non standard perms?"
read PERM_CALL

if [[ $PERM_CALL == 1 ]]; then
        modify_perms
elif [[ $PERM_CALL != 1 ]]; then
        echo "No modifications made"
else
        echo "Invalid entry"
fi

#In the end, sub $HOME for /tmp or something or take a switch value for an output location and send
#       results to this location.
cat $HOME/permissions.txt
cat $HOME/non_std_perms.txt
rm -f $HOME/paths.txt
