#!/bin/sh
#Script to check Oracle, Enforce, and SQLPlus verions and Vontu/SymantecDLP and Oracle Services
#TODO: Get Print status of oracle version and also print outputs prettily


#If Oracle credentials not supplied in command line, get them manually
if [ -z $1 ]; then
	echo "Oracle schema username:"
	read USERNAME
else
	USERNAME=$1
fi

if [ -z $2 ]; then
	echo "Oracle password:"
	read PASS
else 
	PASS=$2
fi


#Connect to SQLPlus with supplied Username and Password and get Enforce and Oracle Version
echo "Connecting to SQLPlus as \"$USERNAME\"..."

#Grab enforce version and output to file named enforceversion in the home directory
sqlplus -s /nolog >~/enforceversion<< EOF
CONNECT $USERNAME/$PASS;
SELECT VERSION FROM enforceversion WHERE ISCURRENTVERSION LIKE 'Y';
exit;
EOF

#Grab oracle version and output to file named oracleversion in the home directory
sqlplus -s /nolog >~/oracleversion<< EOF
CONNECT $USERNAME/$PASS;
SELECT * from v\$version;
exit;
EOF

echo "-----------------------------------------------------------------"
echo "#                    Enforce Version Info                       #"
echo "-----------------------------------------------------------------"
cat ~/enforceversion

echo "-----------------------------------------------------------------"
echo "#                     Oracle Version Info                       #"
echo "-----------------------------------------------------------------"
cat ~/oracleversion



#Check for versions 15.1 or 15.5
if grep -q '15.1\|15.5' ~/enforceversion; then
	echo "-----------------------------------------------------------------"
	echo "#                 SymantecDLP Service Status                    #"
	echo "-----------------------------------------------------------------"
	if !(( $(ps -ef | grep -v grep | grep SymantecDLPDetectionServerService | wc -l ) > 0)); then
		/etc/rc.d/init.d/SymantecDLPDetectionServerService start
	else
		/etc/rc.d/init.d/SymantecDLPDetectionServerControllerService status
	fi
	if !(( $(ps -ef | grep -v grep | grep SymantecDLPDetectionServerControllerService | wc -l ) > 0)); then
		/etc/rc.d/init.d/SymantecDLPDetectionServerControllerService start
	else
		/etc/rc.d/init.d/SymantecDLPDetectionServerService status
	fi
	if !(( $(ps -ef | grep -v grep | grep SymantecDLPIncidentPersisterService | wc -l ) > 0)); then
		/etc/rc.d/init.d/SymantecDLPIncidentPersisterService start
	else
		/etc/rc.d/init.d/SymantecDLPIncidentPersisterService status
	fi
	if !(( $(ps -ef | grep -v grep | grep SymantecDLPManagerService | wc -l ) > 0)); then
		/etc/rc.d/init.d/SymantecDLPManagerService start
	else
		/etc/rc.d/init.d/SymantecDLPManagerService status
	fi
	if !(( $(ps -ef | grep -v grep | grep SymantecDLPNotifierService | wc -l ) > 0)); then
		/etc/rc.d/init.d/SymantecDLPNotifierService start
	else
		/etc/rc.d/init.d/SymantecDLPNotifierService status
	fi
#Check for versions 12.x, 14.x, or 15.0
elif grep -q '12.*\|14.*\|15.0' ~/enforceversion; then
	echo "-----------------------------------------------------------------"
	echo "#                    Vontu Services Status                      #"
	echo "-----------------------------------------------------------------"
	if !(( $(ps -ef | grep -v grep | grep VontuIncidentPersister | wc -l ) > 0)); then
		/etc/rc.d/init.d/VontuIncidentPersister start
	else
		/etc/rc.d/init.d/VontuIncidentPersister status
	fi
	if !(( $(ps -ef | grep -v grep | grep VontuManager | wc -l ) > 0)); then
		/etc/rc.d/init.d/VontuManager start
	else
		/etc/rc.d/init.d/VontuManager status
	fi
	if !(( $(ps -ef | grep -v grep | grep VontuMonitor | wc -l ) > 0)); then
		/etc/rc.d/init.d/VontuMonitor start
	else
		/etc/rc.d/init.d/VontuMonitor status
	fi
	if !(( $(ps -ef | grep -v grep | grep VontuMonitorController | wc -l ) > 0)); then
		/etc/rc.d/init.d/VontuMonitorController start
	else
		/etc/rc.d/init.d/VontuMonitorController status
	fi
	if !(( $(ps -ef | grep -v grep | grep VontuNotifier | wc -l ) > 0)); then
		/etc/rc.d/init.d/VontuNotifier start
	else
		/etc/rc.d/init.d/VontuNotifier status
	fi	
else
	echo "Could not determine Enforce version or Oracle credentials not correct"
	cat ~/enforceversion
	cat ~/oracleversion
fi

#Delete temp files
rm -rf ~/enforceversion
rm -rf ~/oracleversion

