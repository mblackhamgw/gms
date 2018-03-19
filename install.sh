#!/bin/sh

#FUNCTION DEFINITIONS

checkAndUpdateServices() {
    if [ -f /etc/init.d/rc3.d/K50datasync-webadmin ]; then
        insserv -r datasync-webadmin
    fi
    if [ -f /etc/init.d/rc3.d/K50datasync-connectors ]; then
        insserv -r datasync-connectors
    fi
    if [ -f /etc/init.d/rc3.d/K50datasync-syncengine ]; then
        insserv -r datasync-syncengine
    fi
    if [ -f /etc/init.d/rc3.d/K50datasync-configengine ]; then
        insserv -r datasync-configengine
    fi
    if [ -f /etc/init.d/rc3.d/K50datasync-monitorengine ]; then
        insserv -r datasync-monitorengine
    fi
    if [ ! -f /etc/init.d/rc3.d/K50gms ]; then
        insserv gms
    fi
}

updateLogRotateConfiguration()
{
    echo "checking logrotate configuration..."
    python /opt/novell/datasync/common/lib/logrotatesettings.pyc
    echo "$?"
}

compareVersionStrings() {
IFS='.' read -r -a arrayIn <<< "$1"
IFS='.' read -r -a arrayTo <<< "$2"

upgradeNeeded="False"
doneProc="False"
for index in "${!arrayTo[@]}"
do
    if [[ "${arrayTo[index]}" = *"-"* ]]; then
        IFS='-' read -r -a arrayToSub <<< "${arrayTo[index]}"
        IFS='-' read -r -a arrayInSub <<< "${arrayIn[index]}"
        for index2 in "${!arrayToSub[@]}"
        do
            if [ "${arrayToSub[index2]}" != "${arrayInSub[index2]}" ]; then
                if [ $((${arrayToSub[index2]})) = $((${arrayInSub[index2]})) ]; then
                    echo
                elif [ $((${arrayToSub[index2]})) -lt $((${arrayInSub[index2]})) ]; then
                    doneProc="True"
                else
                    upgradeNeeded="True"
                fi
            fi
        done
        if [ "$doneProc" == "True" ]; then
            break
        fi
        if [ "$upgradeNeeded" == "True" ]; then
            break
        fi
    else
        if [ "${arrayTo[index]}" != "${arrayIn[index]}" ]; then
            if [ $((${arrayTo[index]})) = $((${arrayIn[index]})) ]; then
                echo
            elif [ $((${arrayTo[index]})) -lt $((${arrayIn[index]})) ]; then
                upgradeNeeded="False"
                break
            else
                upgradeNeeded="True"
                break
            fi
        fi
    fi
done
}

checkImageMagick() {
	echo "checking installed ImageMagick..."
	imInstalled=`rpm -qa | grep Magick`
	if [ "$imInstalled" = "" ]
	then
		imCoreInstalledStatus="no"
		imWandInstalledStatus="no"
		imInstalledStatus="no"
	else
		imInstalledWithLineFeeds=$(echo $imInstalled | tr " " "\n")
		#Check if we need to upgrade what is installed
		imToInstall=`ls $scriptdir/suse/x86_64/ImageMagick* | awk -F '/' '{print $NF}' | sed -e 's/\.rpm$//'`
		imWandToInstall=`ls $scriptdir/suse/x86_64/libMagickWand* | awk -F '/' '{print $NF}' | sed -e 's/\.rpm$//'`
		imCoreToInstall=`ls $scriptdir/suse/x86_64/libMagickCore* | awk -F '/' '{print $NF}' | sed -e 's/\.rpm$//'`
		imInstalled=""
		imWandInstalled=""
		imCoreInstalled=""
		for im in $imInstalledWithLineFeeds
		do
			echo "im = '$im'"
			if [[ $im == "ImageMagick"* ]];	then
				imInstalled=$im
			elif [[ $im == "libMagickWand"* ]]; then
				imWandInstalled=$im
			elif [[ $im == "libMagickCore"* ]]; then
				imCoreInstalled=$im
			fi
		done
		if [ "$imCoreInstalled" = "" ]
		then
			# libMagicCore is not installed so uninstall the other ImageMagick rpms that are installed
			rpm -e $imInstalled
		else
			# check what is installed
			echo "installed = '$imInstalled'"
			echo "toInstall = '$imToInstall'"
			if [ "$imInstalled" == "" ]; then
				imInstalledStatus="no"
                        else
                                compareVersionStrings $imInstalled $imToInstall
                                if [ "$upgradeNeeded" == "True" ]; then
                                      imInstalledStatus="needsUpgraded"
                                else
                                      imInstalledStatus="yes"
                                      echo "The correct ImageMagick is already installed."
                                fi
			fi
			echo "installed = '$imCoreInstalled'"
			echo "toInstall = '$imCoreToInstall'"
			if [ "$imCoreInstalled" == "" ]; then
				imCoreInstalledStatus="no"
                        else
                                compareVersionStrings $imCoreInstalled $imCoreToInstall
                                if [ "$upgradeNeeded" == "True" ]; then
                                      imCoreInstalledStatus="needsUpgraded"
                                else
                                    imCoreInstalledStatus="yes"
                                    echo "The correct libMagickCore is already installed."
                                fi
			fi
			echo "installed = '$imWandInstalled'"
			echo "toInstall = '$imWandToInstall'"
			if [ "$imWandInstalled" == "" ]; then
				imWandInstalledStatus="no"
                        else
                                compareVersionStrings $imWandInstalled $imWandToInstall
                                if [ "$upgradeNeeded" == "True" ]; then
                                      imWandInstalledStatus="needsUpgraded"
                                else
                                      imWandInstalledStatus="yes"
                                      echo "The correct libMagickWand is already installed."
                                fi
			fi
		fi
	fi
}

getGroupWiseAdminSettings()
{
        gwAdminValidated=""
        while [ -z "$gwAdminValidated" ]
        do
                getGroupWiseAdminHost
                getGroupWiseAdminPort
                getGroupWiseAdminUserName
                getGroupWiseAdminPassword
                verifyGroupWiseAdminCredentials
        done
}

getGroupWiseAdminHost()
{
        gwAdminHostTemp=""
        while [ -z "$gwAdminHostTemp" ]
        do
            if [ "$gwAdminHost" = "" ]
            then
                        printf "GroupWise Administration Agent hostname: "
                        read gwAdminHost
            else
                        read -p "GroupWise Administration Agent hostname [$gwAdminHost]: " gwAdminHost2
                        gwAdminHost=${gwAdminHost2:-$gwAdminHost}
            fi
            if [ "$gwAdminHost" = "" ]
            then
                echo "Please enter a value."
            else
                gwAdminHostTemp="good"
            fi
        done
}

getGroupWiseAdminPort()
{
        gwAdminPortTemp=""
        gwAdminPort="9710"
        while [ -z "$gwAdminPortTemp" ]
        do
            if [ "$gwAdminPort" = "" ]
            then
                printf "GroupWise Administration port: "
                read gwAdminPort
            else
                read -p "GroupWise Administration port [$gwAdminPort]: " gwAdminPort2
                gwAdminPort=${gwAdminPort2:-$gwAdminPort}
            fi
            if [ "$gwAdminPort" = "" ]
            then
                echo "Please enter a value."
            else
                gwAdminPortTemp="good"
            fi
        done
}

getGroupWiseAdminUserName()
{
        gwAdminUserNameTemp=""
        while [ -z "$gwAdminUserNameTemp" ] 
        do
                if [ "$gwAdminUserName" = "" ]
                then
                        printf "GroupWise Administrator user name: "
                        read gwAdminUserName
                else
                        read -p "GroupWise Administration user name [$gwAdminUserName]: " gwAdminUserName2
                        gwAdminUserName=${gwAdminUserName2:-$gwAdminUserName}
                fi
                if [ "$gwAdminUserName" = "" ]
                then
                        echo "Please enter a value."
                else
                        gwAdminUserNameTemp="good"
                fi
        done
}

getGroupWiseAdminPassword()
{
    gwAdminPasswordTemp=""
    while [ -z "$gwAdminPasswordTemp" ]
    do
        echo -n $"GroupWise Administrator password: "
        input=""
        gwAdminPassword=""
        while IFS= read -n1 -s input
        do
            if [ "$input" == "" ]
            then
                break
            fi
            if [ "$input" == $'\177' ]
            then
                if [ "$gwAdminPassword" != "" ]
                then
                    echo -ne '\b \b'
                    gwAdminPassword="${gwAdminPassword%?}"
                fi
            else
                printf "*"
                gwAdminPassword="$gwAdminPassword$input"
            fi
        done
        if [ "$gwAdminPassword" = "" ]
        then
            echo ""
            echo "Please enter a value."
        else
            gwAdminPasswordTemp="good"
        fi
    done
}

verifyGroupWiseAdminCredentials()
{
    echo ""
    python $scriptdir/validateGroupWiseAdmin.pyc -va "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
    #echo "$?"
    gwValidateResult="$?"
    if [ "$gwValidateResult" = "2" ]
    then
        echo "The GroupWise version must be version 18.0 or above.  Please try again."
        gwAdminValidated=""
        sleep 1
    elif [ "$gwValidateResult" = "1" ]
    then
        echo "Please check the entries and try again"
        gwAdminValidated=""
        sleep 1
    else
        #check the license
        python $scriptdir/validateGroupWiseAdmin.pyc -cl "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
        if [ "$?" = "1" ]
        then
            gwAdminValidated=""
            echo "Unable to verify GroupWise Maintenance.  Please try again."
        else
            echo "GroupWise Administration host: $gwAdminHost" >> $logfile
            echo "GroupWise Administration port: $gwAdminPort" >> $logfile
            echo "GroupWise Administrator user name: $gwAdminUserName" >> $logfile
            echo "GroupWise Administrator settings verified" >> $logfile
            gwAdminValidated="yes"
        fi
    fi
}

promptForProperGWVersion()
{
    echo ""
    echo "This version of GroupWise Mobility Service requires GroupWise version 18.0.0 or above."
    sleep 1
    gwVerAvailable=""
    while [ -z "$gwVerAvailable" ]
    do
        gwVerAvailable="yes"
        read -p "Is your GroupWise System version 18.0.0 or above? (yes/no) [$gwVerAvailable]: " gwVerAvailable2
        gwVerAvailabletemp=${gwVerAvailable2:-$gwVerAvailable}
        if [ "$gwVerAvailabletemp" != "yes" -a  "$gwVerAvailabletemp" != "no" ]
        then
            gwVerAvailable=""
        else
            gwVerAvailable=$gwVerAvailabletemp
        fi
    done
}


#################
# START OF SCRIPT
#################

echo "Welcome to the Micro Focus GroupWise Mobility Service install."

id=`id | awk '{print $1}'|awk -F"=" '{print $2}'|awk -F"(" '{print $1}'`

if [ $id != 0 ]
then
    echo "%% You should have root permissions to execute this script."
    exit 1
fi

if [ ! -d /var/log/datasync ]
then
    mkdir /var/log/datasync
fi

logfile="/var/log/datasync/install.log"
scriptInstallFile="/var/log/datasync/script.inst"
rpmswitch=""
slesUpgrade="no"
datasync_prefix=datasync-
ds=datasynchronizer
imageMagick=Magick

if [ -f $scriptInstallFile ]
then
    source $scriptInstallFile
    rpmswitch="--replacefiles"
else
    # Check if this is a new install.
    newinstall="yes"
    if rpm -qa | grep "$datasync_prefix" > /dev/null
    then
       newinstall="no"
    fi
fi
# echo $newinstall
web_server="/etc/datasync/webadmin/server.xml"
web_server_bak="/etc/datasync/webadmin/server.xml.rpmsave"
syncengine_conn="/etc/datasync/syncengine/connectors.xml"
syncengine_conn_bak="/etc/datasync/syncengine/connectors.xml.rpmsave"
syncengine_eng="/etc/datasync/syncengine/engine.xml"
syncengine_eng_bak="/etc/datasync/syncengine/engine.xml.rpmsave"
configengine_config="/etc/datasync/configengine/configengine.xml"
configengine_config_bak="/etc/datasync/configengine/configengine.xml.rpmsave"
configengine_eng="/etc/datasync/configengine/engines/default/engine.xml"
configengine_eng_bak="/etc/datasync/configengine/engines/default/engine.xml.rpmsave"
mob_ca_pem="/var/lib/datasync/mobility/mob_ca.pem"
mob_ca_pem_bak="/var/lib/datasync/mobility/mob_ca.pem.rpmsave"
if [ "$newinstall" = "yes" ]
then
    if [[ ! -f $web_server && -f $web_server_bak && ! -f $syncengine_conn && -f $syncengine_conn_bak && ! -f $syncengine_eng && -f $syncengine_eng_bak && ! -f $configengine_config && -f $configengine_config_bak && ! -f $configengine_eng && -f $configengine_eng_bak ]]
    then
        slesUpgrade="yes"
        echo "SLES 11-12 upgrade"
    else
        echo "no SLES upgrade"
    fi
fi
if [ ! -f $scriptInstallFile ]
then
    # Create the script.inst file ...
    echo "newinstall=\"$newinstall\"
slesUpgrade=\"$slesUpgrade\"" > /var/log/datasync/script.inst
fi

# Get the directory that the script is in
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Import the RPM signing key
rpmKeyFile=$scriptdir/content.key
if [ ! -f $rpmKeyFile ]; then
	echo "RPM signing key file not found.  Can not import the key."
	echo "You will get warnings when installing the RPM's, however, the RPM's will install correctly"
else
	rpm --import $rpmKeyFile
fi

acceptEULA=""
more $scriptdir/license.txt

while [ -z "$acceptEULA" ]
do
    acceptEULA="yes"
    read -p "Accept GMS EULA? (yes/no) [$acceptEULA]: " acceptEULA2
    acceptEULAtemp=${acceptEULA2:-$acceptEULA}
    if [ "$acceptEULAtemp" != "yes" -a  "$acceptEULAtemp" != "no" ]
    then
	acceptEULA=""
    else
        acceptEULA=$acceptEULAtemp
    fi
done
if [ "$acceptEULA" = "no" ]
then
    exit 1
fi

echo "Starting GMS install: $(date)" >> $logfile

if [ "$newinstall" = "yes" ]
then
{
    echo "NEW INSTALL"
} | tee -a $logfile

#check if the network setting are correctly configured
FQDN_NAME=`/bin/hostname --fqdn`
if [ $? -ne 0 ] || [ -z "$FQDN_NAME" ]
then
    echo "There seems to be issues with the network settings."
    echo "Please make sure 'hostname -f' returns a valid hostname ... exiting."
    echo "There seems to be issues with the network settings. Please make sure 'hostname -f' returns a valid hostname ... exiting." >> $logfile
    exit 1
fi

    promptForProperGWVersion
    if [ "$gwVerAvailable" = "no" ]
    then
        exit 1
    fi
   # Silent install will by-pass all of this and pull the data from a file passed in on the command line.
    if [ "$1" = "" ]
    then
	provision=""
	ldapvalidated=""
	ldaphost=""
	ldapsecure=""
	ldapport="636"
	ldapadmin=""
	ldappass=""
	gwhost=""
	gwport="7191"
	gwsecure=""
	gwappkeypath=""
	gwappkeyvalue=""
	gwappname=""
	galuser=""
	dbpass=""
	devsecure=""
	devport="443"
	devcertselfsigned=""
	devcertpath=""
	ccrNow=""
	ccrEmail=""
	ccrCode=""

        #install common and common-lib-requests rpms
#        dscommon="`ls $scriptdir/suse/x86_64/datasync-common-??.*`"
#        rpm -i $dscommon
#        dscomrequests="`ls $scriptdir/suse/x86_64/datasync-common-lib-request*`"
#        rpm -i $dscomrequests

#        getGroupWiseAdminSettings

# install postgres
{
        if [ "$slesUpgrade" = "yes" ]
        then
            if rpm -qa | grep "$ds" > /dev/null
            then
                uninstall_list=`rpm -qa | grep "$ds"`
                echo "Uninstalling datasynchronizer mobilitypack rpms..."
                uninstall_list="`echo -n $uninstall_list | tr '\n' ' '`"
                rpm -e $uninstall_list
            fi
        fi
	echo "Installing postgreSQL..."
	zypper -n in postgresql-server
# install rpms from suse/x86_64/ directory ... we need to do this here because we use some of the GMS modules to validate the input
	echo "Installing ImageMagick..."
	zypper -n in ImageMagick
	checkImageMagick

	if [ "$imInstalledStatus" = "no" ] || [ "$imCoreInstalledStatus" = "no" ] || [ "$imWandInstalledStatus" = "no" ]
	then
	    echo "ImageMagick failed to install from repos.  Installing from GMS distro..."
	    
		LIBGOMP1="libgomp1"
		if zypper -n se $LIBGOMP1 | grep -o 'No matching items found' > /dev/null
		then
		    LIBGOMP1=''
		else
		    echo "Installing" $LIBGOMP1 "..."
		    zypper -n in $LIBGOMP1
		fi
		
		if [ "$imCoreInstalledStatus" = "no" ]; then
			magickCore="`ls $scriptdir/suse/x86_64/libMagickCore*`"
			rpm -i $magickCore
		fi
		if [ "$imWandInstalledStatus" = "no" ]; then
			magickwand="`ls $scriptdir/suse/x86_64/libMagickWand*`"
			rpm -i $magickwand
		fi
		if [ "$imInstalledStatus" = "no" ]; then
			imagemagick="`ls $scriptdir/suse/x86_64/ImageMagick*`"
			rpm -i $imagemagick
		fi
	else
		if [ "$imCoreInstalledStatus" = "needsUpgraded" ]; then
                	magickCore="`ls $scriptdir/suse/x86_64/libMagickCore*`"
	                rpm -U $magickCore
		fi
		if [ "$imWandInstalledStatus" = "needsUpgraded" ]; then
                	magickwand="`ls $scriptdir/suse/x86_64/libMagickWand*`"
	                rpm -U $magickwand
		fi
		if [ "$imInstalledStatus" = "needsUpgraded" ]; then
                	imagemagick="`ls $scriptdir/suse/x86_64/ImageMagick*`"
	                rpm -U $imagemagick
		fi
	fi
	echo "Installing unixODBC..."
	zypper -n in unixODBC
	
	PYTHON_LDAP="python-pyldap"
	if zypper -n se python-pyldap | grep -o 'No packages found' > /dev/null
	then
	    PYTHON_LDAP="python-ldap"
	else
	    PYTHON_LDAP="python-pyldap"
	fi
	echo "Installing" $PYTHON_LDAP "..."
	
	zypper -n in $PYTHON_LDAP
        if rpm -qa | grep $PYTHON_LDAP > /dev/null
        then
            echo $PYTHON_LDAP "installed successfully"
        else
            pldap="`ls $scriptdir/suse/x86_64/$PYTHON_LDAP*`"
            if [ "$pldap" != "" ]
            then
                if [ -f $pldap ]
                then
                    ppyasn="`ls $scriptdir/suse/noarch/python-pyasn1*`"
                    if [ "$ppyasn" != "" ]
                    then
                        if [ -f $ppyasn ]
                        then
                            rpm -i $ppyasn
                            rpm -i $pldap
                        else
                            echo "cannot find python-pyasn1 in ISO image"
                        fi
                    else
                        echo "cannot find python-pyasn1 in ISO image"
                    fi
                else
                    echo "cannot find" $PYTHON_LDAP "in ISO image"
                fi
            else
                echo "cannot find" $PYTHON_LDAP "in ISO image"
            fi
        fi
        if rpm -qa | grep $PYTHON_LDAP > /dev/null
        then
            echo $PYTHON_LDAP "installed successfully"
        else
            echo "Fatal error - could not install" $PYTHON_LDAP
            exit 1
        fi
	echo "Installing python-openssl..."
	zypper -n in python-openssl
	echo "Installing python-M2Crypto..."
	zypper -n in python-M2Crypto
	echo "Installing python-lxml..."
        zypper -n in python-lxml
        echo "Installing librtfcomp0..."
        librtf="`ls $scriptdir/suse/x86_64/librtfcomp0*`"
        rpm -i --force $librtf
	echo "Installing psqlODBC..."
	psqlodbc="`ls $scriptdir/suse/x86_64/psqlODBC*`"
	rpm -i $psqlodbc
	echo "Installing python-pyodbc..."
	pyodbc="`ls $scriptdir/suse/x86_64/python-pyodbc*`"
	rpm -i $pyodbc
	echo "Installing python-psycopg2..."
	psycopg="`ls $scriptdir/suse/x86_64/python-psycopg*`"
	rpm -i $psycopg
	echo "Installing python-rtfcomp..."
	prtfcomp="`ls $scriptdir/suse/x86_64/python-rtf*`"
	rpm -i $prtfcomp
	echo "Installing GMS rpms..."
	dsList="`ls $scriptdir/suse/x86_64/datasync-*`"
	rpm -i $rpmswitch $dsList
} | tee -a $logfile

	if rpm -qa | grep "$datasync_prefix" > /dev/null
	then
	    echo "rpms installed successfully"
	else
	    echo "The GMS rpms failed to install.  You must have a Software Repository configured for SLES 12."
	    exit 1
	fi

	# Update the services
	checkAndUpdateServices
	updateLogRotateConfiguration

	# Fix python so that dashboard works
	echo "Check python"
        updatePython="False"
	if [ -d /usr/lib64/python2.7 ]
	then
	    if [ -f /usr/lib64/python2.7/httplib.py.gms ]
	    then
                if grep "if body:" /usr/lib64/python2.7/httplib.py > /dev/null
                then
                    echo "python httplib has already been updated." 1>&2
                else
                    mv /usr/lib64/python2.7/httplib.py.gms /usr/lib64/python2.7/httplib.py.gms.old
                    updatePython="True"
                fi
            else
                updatePython="True"
            fi
            if [ "$updatePython" = "True" ]
            then
                echo "updating python httplib..." 1>&2
                sed -i.gms 's/        self.endheaders(body)/#        self.endheaders(body)\n        if body:\n            self.endheaders(body)\n        else:\n            self.endheaders()/g' /usr/lib64/python2.7/httplib.py
	    fi
	fi
	clear

#        getGroupWiseAdminSettings
#        python $scriptdir/validateGroupWiseAdmin.pyc -gc "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
#        if [ "$?" = "1" ]
#        then
#            echo "Unable to get the GroupWise CA Public Certificate.  The install cannot continue."
#            exit 1
#        fi
#        python $scriptdir/validateGroupWiseAdmin.pyc -cl "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
#        if [ "$?" = "1" ]
#        then
#            echo "Unable to verify GroupWise Maintenance.  The install cannot continue."
#            exit 1
#        fi

        if [ "$slesUpgrade" = "yes" ]
        then
            slesUpgrade=""
            while [ -z "$slesUpgrade" ]
            do
                slesUpgrade="yes"
                read -p "The install has detected that this server was upgraded from SLES 11 running GMS.  Is this correct? (yes/no) [$slesUpgrade]: " slesUpgrade2
                slesUpgradetemp=${slesUpgrade2:-$slesUpgrade}
                if [ "$slesUpgradetemp" != "yes" -a  "$slesUpgradetemp" != "no" ]
                then
                    slesUpgrade=""
                else
                    slesUpgrade=$slesUpgradetemp
                fi
            done
            if [ "$slesUpgrade" = "no" ]
            then
                # Update the script.inst file ...
                echo "newinstall=\"$newinstall\"
slesUpgrade=\"$slesUpgrade\"" > /var/log/datasync/script.inst
            fi
        else
            getGroupWiseAdminSettings
            python $scriptdir/validateGroupWiseAdmin.pyc -gc "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
            if [ "$?" = "1" ]
            then
                echo "Unable to get the GroupWise CA Public Certificate.  The install cannot continue."
                exit 1
            fi
            python $scriptdir/validateGroupWiseAdmin.pyc -cl "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
            if [ "$?" = "1" ]
            then
                echo "Unable to verify GroupWise Maintenance.  The install cannot continue."
                exit 1
            fi
        fi

	if [ "$slesUpgrade" = "no" ]
	then
	    echo "Running GMS configuration:"
	    echo ""
	    # query for config info
	    while [ -z "$provision" ]
	    do
		provision=groupwise
		read -p "Specify the provisioning source (groupwise/ldap) [$provision]: " provision2
		provisiontemp=${provision2:-$provision}
		if [ "$provisiontemp" != "groupwise" -a  "$provisiontemp" != "ldap" ]
		then
		    provision=""
		else
		    provision=$provisiontemp
		fi
	    done
	    echo "Specify the provisioning source: $provision" >> $logfile
	    if [ "$provision" = "ldap" ]
	    then
		while [ -z "$ldapvalidated" ]
		do
		    ldaphosttemp=""
		    while [ -z "$ldaphosttemp" ]
		    do
			if [ "$ldaphost" = "" ]
			then
			    printf "LDAP Server IP address or hostname: "
			    read ldaphost
			else
			    read -p "LDAP Server IP address or hostname [$ldaphost]: " ldaphost2
			    ldaphost=${ldaphost2:-$ldaphost}
			fi
			if [ "$ldaphost" = "" ]
			then
			    echo "Please enter a value."
			else
			    ldaphosttemp="good"
			fi
		    done
		    ldapporttemp=""
		    while [ -z "$ldapporttemp" ]
		    do
			read -p "LDAP port [$ldapport]: " ldapport2
			ldapport=${ldapport2:-$ldapport}
			if [ "$ldapport" = "" ]
			then
			    echo "Please enter a value."
			else
			    ldapporttemp="good"
			fi
		    done
		    while [ -z "$ldapsecure" ]
		    do
			ldapsecure="yes"
			read -p "LDAP server secure (yes/no) [$ldapsecure]: " ldapsecure2
			ldapsecuretemp=${ldapsecure2:-$ldapsecure}
			if [ "$ldapsecuretemp" != "yes" -a  "$ldapsecuretemp" != "no" ]
			then
			    ldapsecure=""
			else
			    ldapsecure=$ldapsecuretemp
			fi
##      	              echo ""
		    done
		    ldapadmintemp=""
		    while [ -z "$ldapadmintemp" ]
		    do
			if [ "$ldapadmin" = "" ]
			then
			    read -p "LDAP admin dn: " ldapadmin
			else
			    read -p "LDAP admin dn [$ldapadmin]: " ldapadmin2
			    ldapadmin=${ldapadmin2:-$ldapadmin}
			fi
			if [ "$ldapadmin" = "" ]
			then
			    echo "Please enter a value."
			else
			    ldapadmintemp="good"
			fi
		    done
		    ldappasstemp=""
		    while [ -z "$ldappasstemp" ]
		    do
			echo -n $"LDAP admin password: "
#       	        read -s ldappass
			input=""
			ldappass=""
			while IFS= read -n1 -s input
			do
			    if [ "$input" == "" ]
			    then
				break
			    fi
			    if [ "$input" == $'\177' ]
			    then
				if [ "$ldappass" != "" ]
				then
				    echo -ne '\b \b'
				    ldappass="${ldappass%?}"
				fi
			    else
				printf "*"
				ldappass="$ldappass$input"
			    fi
			done
			if [ "$ldappass" = "" ]
			then
			    echo ""
			    echo "Please enter a value."
			else
			    ldappasstemp="good"
			fi
		    done
		    echo ""
		    python /opt/novell/datasync/syncengine/connectors/mobility/cli/LdapValidate.pyc "$ldaphost" "$ldapport" "$ldapadmin" "$ldappass"
		    if [ "$?" = "0" ]
		    then
			echo "LDAP credentials verified."
			ldapvalidated="yes"
		    else
			echo "Try again."
			ldapsecure=""
		    fi
		done
		echo "LDAP Server IP address or hostname: $ldaphost" >> $logfile
		echo "LDAP port: $ldapport" >> $logfile
		echo "LDAP server secure: $ldapsecure" >> $logfile
		echo "LDAP admin dn: $ldapadmin" >> $logfile
		echo "LDAP admin password: **********" >> $logfile
		echo "LDAP credentials verified." >> $logfile
    
		# Build ldap URL
		if [ $ldapsecure = "yes" ]
		then
                    ldapsecure="true"
		    ldapurl="ldaps://$ldaphost:$ldapport"
		else
                    ldapsecure="false"
		    ldapurl="ldap://$ldaphost:$ldapport"
		fi
		# Get the ldap users container
		pass=$ldappass
		export pass
		usercontainervalidated=""
		while [ -z "$usercontainervalidated" ]
		do
		    ldapusertemp=""
		    while [ -z "$ldapusertemp" ]
		    do
			printf "LDAP user container: "
			read ldapuser
			if [ "$ldapuser" = "" ]
			then
			    echo "Please enter a value."
			else
			    # validate it...
			    result=$(python  /opt/novell/datasync/syncengine/connectors/mobility/cli/ug_check.pyc --url="$ldapurl" --admin="$ldapadmin" --type='container' --dn="$ldapuser")
			    if [ "$result" = "true" ]
			    then
				echo "User container verified."
				usercontainervalidated="yes"
				ldapusertemp="good"
			    else
				echo "Invalid container.  Please try again."
				ldapuser=""
			    fi
			fi
		    done
##      	         echo ""
		done
    
		echo "LDAP user container: $ldapuser" >> $logfile
		# Get the ldap group container
		groupcontainervalidated=""
		while [ -z "$groupcontainervalidated" ]
		do
		    read -p "LDAP group container [$ldapuser]: " ldapgroup
		    ldapgroup=${ldapgroup:-$ldapuser}
		    # validate it...
		    result=$(python  /opt/novell/datasync/syncengine/connectors/mobility/cli/ug_check.pyc --url="$ldapurl" --admin="$ldapadmin" --type='container' --dn="$ldapgroup")
		    if [ "$result" = "true" ]
		    then
			echo "Group container verified."
			groupcontainervalidated="yes"
		    else
			echo "Invalid container.  Please try again."
			ldapgroup=""
		    fi
##      	         echo ""
		done
		echo "LDAP group container: $ldapgroup" >> $logfile
	    fi
    
	    # Get db password and validate
	    dbpasstemp=""
	    dbpwdvalidated=""
	    while [ -z "$dbpwdvalidated" ]
	    do
		while [ -z "$dbpasstemp" ]
		do
		    printf "GMS database password: "
		    input=""
		    dbpass=""
		    while IFS= read -n1 -s input
		    do
			if [ "$input" == "" ]
			then
			    break
			fi
			if [ "$input" == $'\177' ]
			then
			    if [ "$dbpass" != "" ]
			    then
				echo -ne '\b \b'
				dbpass="${dbpass%?}"
			    fi
			else
			    printf "*"
			    dbpass=$dbpass$input
			fi
		    done
		    if [ "$dbpass" = "" ]
		    then
			echo ""
			echo "Please enter a value."
		    else
			dbpasstemp="good"
		    fi
		done
		echo ""
#       	    read dbpass
		printf "Verify GMS database password: "
		input=""
		dbpass2=""
		while IFS= read -n1 -s input
		do
		    if [ "$input" == "" ]
		    then
			break
		    fi
		    if [ "$input" == $'\177' ]
		    then
			if [ "$dbpass2" != "" ]
			then
			    echo -ne '\b \b'
			    dbpass2="${dbpass2%?}"
			fi
		    else
			printf "*"
			dbpass2="$dbpass2$input"
		    fi
		done
#       	    read dbpass2
		echo ""
		if [ "$dbpass" = "$dbpass2" ]
		then
		    dbpwdvalidated="yes"
		else
		    dbpasstemp=""
		    echo "Passwords don't match, please try again."
		fi
	    done
    
	    echo "GMS database password: **********" >> $logfile
	    # Gather the GW info
	    gwvalidated=""
	    while [ -z "$gwvalidated" ]
	    do
		gwappnametemp=""
		while [ -z "$gwappnametemp" ]
		do
		    if [ "$gwappname" = "" ]
		    then
			read -ep "GroupWise trusted application name: " gwappname
		    else
			read -ep "GroupWise trusted application name [$gwappname]: " gwappname2
			gwappname=${gwappname2:-$gwappname}
		    fi
		    if [ "$gwappname" = "" ]
		    then
			echo "Please enter a value."
		    else
			gwappnametemp="good"
		    fi
		done
    
		gwappkeypathtemp=""
		while [ -z "$gwappkeypathtemp" ]
		do
		    if [ "$gwappkeypath" = "" ]
		    then
			read -ep "GroupWise trusted application key file path: " gwappkeypath
		    else
			read -ep "GroupWise trusted application key file path [$gwappkeypath]: " gwappkeypath2
			gwappkeypath=${gwappkeypath2:-$gwappkeypath}
		    fi
		    # validate the path entered
		    if [ ! -f $gwappkeypath ]
		    then
			echo "The path does not exist, please try again."
			gwappkeypath=""
		    elif [ "$gwappkeypath" = "" ]
		    then
			echo "Please enter a value."
		    else
			gwappkeypathtemp="good"
		    fi
		done
    
		gwhosttemp=""
		while [ -z "$gwhosttemp" ]
		do
		    if [ "$gwhost" = "" ]
		    then
			printf "GroupWise Post Office Agent IP address or hostname: "
			read gwhost
		    else
			read -p "GroupWise Post Office Agent IP address or hostname [$gwhost]: " gwhost2
			gwhost=${gwhost2:-$gwhost}
		    fi
		    if [ "$gwhost" = "" ]
		    then
			echo "Please enter a value."
		    else
			gwhosttemp="good"
		    fi
		done
    
		if [ "$gwport" = "" ]
		then
		    printf "SOAP port: "
		    read gwport
		else
		    read -p "SOAP port [$gwport]: " gwport2
		    gwport=${gwport2:-$gwport}
		fi
    
		while [ -z "$gwsecure" ]
		do
		    gwsecure="yes"
		    read -p "Secure SOAP (yes/no) [$gwsecure]: " gwsecure2
		    gwsecuretemp=${gwsecure2:-$gwsecure}
		    if [ "$gwsecuretemp" != "yes" -a  "$gwsecuretemp" != "no" ]
		    then
			gwsecure=""
		    else
			gwsecure=$gwsecuretemp
		    fi
##      	          echo ""
		done
    
		if [ "$gwsecure" = "yes" ]
		then
		    gwurl="https://$gwhost:$gwport"
		else
		    gwurl="http://$gwhost:$gwport"
		fi
    
		# Read the app key from the file
		gwappkeyvalue=$(head -n 1 $gwappkeypath)
		result=$(python /opt/novell/datasync/syncengine/connectors/mobility/cli/gw_login.pyc --gw="$gwurl" --appname="$gwappname" --key="$gwappkeyvalue")
		if [ "$result" = "true" ]
		then
		    echo "GroupWise settings verified."
		    gwvalidated="yes"
		else
		    echo $result
		    echo "Please check the entries and try again"
		    gwsecure=""
		fi
	    done
    
	    echo "GroupWise trusted application name: **********" >> $logfile
	    echo "GroupWise trusted application key file path: $gwappkeypath" >> $logfile
	    echo "GroupWise Post Office Agent IP address or hostname: $gwhost" >> $logfile
	    echo "SOAP port: $gwport" >> $logfile
	    echo "Secure SOAP: $gwsecure" >> $logfile
	    echo "GroupWise settings verified" >> $logfile

	    # Get secure connection info
	    read -p "Device connection port [$devport]: " devport2
	    devport=${devport2:-$devport}
    
	    echo "Device connection port: $devport" >> $logfile
	    while [ -z "$devsecure" ]
	    do
		devsecure="yes"
		read -p "Use secure connections for device communication (yes/no) [$devsecure]: " devsecure2
		devsecuretemp=${devsecure2:-$devsecure}
		if [ "$devsecuretemp" != "yes" -a  "$devsecuretemp" != "no" ]
		then
		    devsecure=""
		else
		    devsecure=$devsecuretemp
		fi
##      	      echo ""
	    done
    
	    echo "Use secure connections for device communication: $devsecure" >> $logfile
	    if [ "$devsecure" = "yes" ]
	    then
		devsecure="true"
	    else
		devsecure="false"
	    fi
    
	    if [ "$devsecure" = "true" ]
	    then
		while [ -z "$devcertselfsigned" ]
		do
		    devcertselfsigned="yes"
		    read -p "Generate self-signed certificate (yes/no) [$devcertselfsigned]: " devcertselfsigned2
		    devcerttemp=${devcertselfsigned2:-$devcertselfsigned}
		    if [ "$devcerttemp" != "yes" -a "$devcerttemp" != "no" ]
		    then
			devcertselfsigned=""
		    elif [ "$devcerttemp" = "yes" ]
		    then
			devcertselfsigned="true"
		    else
			devcertselfsigned="false"
		    fi
		done
		echo "Generate self-signed certificate: $devcertselfsigned" >> $logfile
		if [ "$devcertselfsigned" = "true" ]
		then
		    devcertpath="''"
		else
		    devcertpathtemp=""
		    while [ -z "$devcertpathtemp" ]
		    do
			printf "Certificate file path: "
			read devcertpath
			# validate the path
			if [ ! -f $devcertpath ]
			then
			    echo "The path does not exist, please try again."
			    devcertpath=""
			elif [ "$devcertpath" = "" ]
			then
			    echo "Please enter a value."
			else
			    devcertpathtemp="good"
			fi
		    done
		    echo "Certificate file path: $devcertpath" >> $logfile
		fi
	    else
		devcertselfsigned="true"
		devcertpath="''"
	    fi
    
	    # Get gal user
	    while [ -z "$galuser" ]
	    do
		printf "Enter the GroupWise address book user: "
		read galuser
		if [ "$galuser" = "" ]
		then
		    echo "Please enter a value."
		fi
	    done
	    echo "Enter the GroupWise address book user: $galuser" >> $logfile
	fi
       # Handle Customer Center Configuration.
##       while [ -z "$ccrNow" ]
##       do
##            printf "Register with Novell Customer Center? (yes/no): "
##            read ccrNow
##            if [ "$ccrNow" != "yes" -a  "$ccrNow" != "no" ]
##            then
##                    ccrNow=""
##            fi
###            echo ""
##       done
##       if [ "$ccrNow" = "yes" ]
##       then
##           #Get the email address and validate
##           ccrEmailValidated=""
##           while [ -z "$ccrEmailValidated" ]
##           do
##               printf "Enter your email address: "
##               read ccrEmail
###               echo ""
##               printf "Confirm your email address: "
##               read ccrEmail2
###               echo ""
##               if [ "$ccrEmail" = "$ccrEmail2" ]
##               then
##                   ccrEmailValidated="yes"
##               else
##                   echo "Email addresses don't match, please try again."
##               fi
##           done
##           printf "Enter your activation code: "
##           read ccrCode
##       fi
    else

{
	# Silent install
	echo "Silent install"
	echo "reading input from $1 ..."
	source $1
	echo "done"

# install postgres
	echo "Installing postgreSQL..."
	zypper -n in postgresql-server
#       zypper in postgresql-server
# install rpms from suse/x86_64/ directory
	echo "Installing ImageMagick..."
	zypper -n in ImageMagick
	echo "Installing odbc..."
	zypper -n in libodbc.so
	
	PYTHON_LDAP="python-pyldap"
	if zypper -n se python-pyldap | grep -o 'No packages found' > /dev/null
	then
	    PYTHON_LDAP="python-ldap"
	else
	    PYTHON_LDAP="python-pyldap"
	fi
	echo "Installing" $PYTHON_LDAP "..."
	zypper -n in $PYTHON_LDAP
	
	echo "Installing python-openssl..."
	zypper -n in python-openssl
	echo "Installing python-M2Crypto..."
	zypper -n in python-M2Crypto
	echo "Installing python-lxml..."
	zypper -n in python-lxml
	echo "Installing GMS rpms..."
	rpm -i $rList
} | tee -a $logfile

    fi
{
    if [ "$slesUpgrade" = "no" ]
    then
	if [ "$localip" = "" ]
	then
	    # Get the local IP address.
	    localip=$(hostname -i | cut -f1 -d' ')
            if [ "$localip" = "" ]
            then
               localip=$(curl -s http://whatismyip.akamai.com)
            fi
            if [ "$localip" = "" ]
            then
                while [ -z "$localip" ]
                do
                    printf "Enter the IP address of the local server: "
                    read localip
                    if [ "$localip" = "" ]
                    then
                        echo "Please enter a value."
                    fi
                done
            fi
#   	python /opt/novell/datasync/common/lib/getIPAddrs.py
#   	source /opt/novell/datasync/common/lib/ipAddrs.in
	    echo "local IP address: $localip"
	fi
    
	# Should have everything gathered now and can run through the config steps
	cmd_with_no_pass="MUSER='datasync_user' MUSERPASS='******' /opt/novell/datasync/syncengine/connectors/mobility/cli/postgres_setup_1.sh"
	echo "executing: $cmd_with_no_pass"
	MUSER='datasync_user' MUSERPASS="$dbpass" /opt/novell/datasync/syncengine/connectors/mobility/cli/postgres_setup_1.sh
	echo "return code from postgress_setup_1.sh: "
	echo "$?"
    
	cmd="python /opt/novell/datasync/syncengine/connectors/mobility/cli/odbc_setup_2.pyc"
	echo "executing: $cmd"
	$cmd
	echo "return code from odbc_setup_2: "
	echo "$?"
    
	if [ "$provision" = "ldap" ]
	then
#   	    cmd_with_pass="python /opt/novell/datasync/syncengine/connectors/mobility/cli/mobility_setup_3.pyc --provision $provision --dbpass "$dbpass" --ldapgroup "$ldapgroup" --ldapuser "$ldapuser" --ldapadmin "$ldapadmin" --ldappass "$ldappass" --ldaphost $ldaphost --ldapport $ldapport --ldapsecure $ldapsecure --webadmin "$ldapuser""
	    cmd_with_no_pass="python /opt/novell/datasync/syncengine/connectors/mobility/cli/mobility_setup_3.pyc --provision '$provision' --dbpass '******' --ldapgroup '$ldapgroup' --ldapuser '$ldapuser' --ldapadmin '$ldapadmin' --ldappass '******' --ldaphost $ldaphost --ldapport $ldapport --ldapsecure $ldapsecure --webadmin '$ldapuser'"
	else
#   	    cmd_with_pass="python /opt/novell/datasync/syncengine/connectors/mobility/cli/mobility_setup_3.pyc --provision $provision --dbpass $dbpass"
	    cmd_with_no_pass="python /opt/novell/datasync/syncengine/connectors/mobility/cli/mobility_setup_3.pyc --provision $provision --dbpass '******'"
	fi
	echo "executing: $cmd_with_no_pass"
	if [ "$provision" = "ldap" ]
	then
	    python /opt/novell/datasync/syncengine/connectors/mobility/cli/mobility_setup_3.pyc --provision $provision --dbpass "$dbpass" --ldapgroup "$ldapgroup" --ldapuser "$ldapuser" --ldapadmin "$ldapadmin" --ldappass "$ldappass" --ldaphost $ldaphost --ldapport $ldapport --ldapsecure $ldapsecure --webadmin "$ldapuser"
	else
	    python /opt/novell/datasync/syncengine/connectors/mobility/cli/mobility_setup_3.pyc --provision $provision --dbpass $dbpass
	fi
#   	$cmd_with_pass
	echo "return code from mobility_setup_3.pyc: "
	echo "$?"
    
	cmd="/opt/novell/datasync/syncengine/connectors/mobility/cli/enable_setup_4.sh"
	echo "executing: $cmd"
	$cmd
	echo "return code from enable_setup_4.sh: "
	echo "$?"
    
	cmd="python /opt/novell/datasync/syncengine/connectors/mobility/cli/mobility_setup_5.pyc --provision $provision --galuser "$galuser" --block false --selfsigned $devcertselfsigned --path $devcertpath --lport $devport --secure $devsecure"
	echo "executing: $cmd"
	$cmd
	echo "return code from activesync_setup_5.pyc: "
	echo "$?"
    
#   	cmd_with_pass="python /opt/novell/datasync/syncengine/connectors/mobility/cli/groupwise_setup_6.pyc --keypath $gwappkeypath --lport 4500 --lip $localip --version 802 --soap $gwhost --key "$gwappname" --sport $gwport --psecure $gwsecure"
	cmd_with_no_pass="python /opt/novell/datasync/syncengine/connectors/mobility/cli/groupwise_setup_6.pyc --keypath '******' --lport '4500' --lip '$localip' --version '802' --soap $gwhost --key '$gwappname' --sport $gwport --psecure '$gwsecure' --adminaddress '$gwAdminHost' --adminport '$gwAdminPort' --adminusername '******' --adminuserpwd '******'"
	echo "executing: $cmd_with_no_pass"
	python /opt/novell/datasync/syncengine/connectors/mobility/cli/groupwise_setup_6.pyc --keypath $gwappkeypath --lport 4500 --lip $localip --version 802 --soap $gwhost --key "$gwappname" --sport $gwport --psecure $gwsecure --adminaddress $gwAdminHost --adminport $gwAdminPort --adminusername $gwAdminUserName --adminuserpwd $gwAdminPassword 
#   	$cmd_with_pass
	echo "return code from groupwise_setup_6.pyc: "
	echo "$?"

        cmd="python /opt/novell/datasync/syncengine/connectors/mobility/cli/validateGroupWiseAdmin.pyc -sl"
        echo "executing: $cmd"
        $cmd
        echo "return code from validateGroupWiseAdmin.pyc: "
        echo "$?"
    
	cmd="python /opt/novell/datasync/syncengine/connectors/mobility/cli/start_mobility.pyc"
	echo "executing: $cmd"
	$cmd
	echo "return code from start_mobility.pyc: "
	echo "$?"
    else
	echo "Detected SLES 11/12 upgrade"
	mv $web_server_bak $web_server
	mv $syncengine_conn_bak $syncengine_conn
	mv $syncengine_eng_bak $syncengine_eng
	mv $configengine_config_bak $configengine_config
	mv $configengine_eng_bak $configengine_eng
        if [[ -f $mob_ca_pem_bak ]]
        then
            mv $mob_ca_pem_bak $mob_ca_pem
        fi
        systemctl enable gms
        # Update the script.inst file ...
        echo "newinstall=\"no\"
slesUpgrade=\"no\"" > /var/log/datasync/script.inst
	/opt/novell/datasync/update.sh
    fi
} | tee -a $logfile

else
    gwaCAChecked=""
    gwaLicenseChecked=""
    credentialsEntered="False"
    while [[ -z "$gwaCAChecked" && -z "$gwaLicenseChecked" ]]
    do
        if [ "$credentialsEntered" = "False" ]
        then
            #check for existing gwAdmin in connector.xml
            python $scriptdir/validateGroupWiseAdmin.pyc -vs
            if [ "$?" = "1" ]
            then
                promptForProperGWVersion
                if [ "$gwVerAvailable" = "no" ]
                then
                    exit 1
                fi
                getGroupWiseAdminSettings
                credentialsEntered="True"
            fi
        fi
        #get the GW CA cert
        if [ "$credentialsEntered" = "True" ]
        then
            python $scriptdir/validateGroupWiseAdmin.pyc -gc "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
            if [ "$?" = "1" ]
            then
                echo "Unable to get the GroupWise CA Public Certificate.  The install cannot continue."
                exit 1
            else
                gwaCAChecked="good"
            fi
            python $scriptdir/validateGroupWiseAdmin.pyc -cl "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
            result="$?"
            if [ "$result" != "0" ]
            then
                echo "Unable to verify GroupWise Maintenance.  The install cannot continue."
                exit 1
            else
                gwaLicenseChecked="good"
            fi
        else
            python $scriptdir/validateGroupWiseAdmin.pyc -gc
            if [ "$?" = "1" ]
            then
                echo "Unable to get the GroupWise CA Public Certificate.  The install cannot continue."
                exit 1
            else
                gwaCAChecked="good"
            fi
            python $scriptdir/validateGroupWiseAdmin.pyc -cl
            result="$?"
            if [ "$result" != "0" ]
            then
                if [ "$result" = "99" ]
                then
                    echo "Connection error while verifying GroupWise Maintenance.  Please enter your GroupWise Admin info again."
                    echo ""
                    getGroupWiseAdminSettings
                    gwaCAChecked=""
                    credentialsEntered="True"
                else
                    echo "Unable to verify GroupWise Maintenance.  The install cannot continue."
                    exit 1
                fi
            else
                gwaLicenseChecked="good"
            fi
        fi
    done
{   
    echo "UPGRADE INSTALL"
    echo "Checking python-lxml..." 1>&2
    if rpm -qa | grep "python-lxml-2" > /dev/null
    then
        echo "Upgrading python-lxml..." 1>&2
        #figure out the version of python-lxml that is available.
        plxml="`zypper in python-lxml`"
        #remove new lines
        plxml="`echo -n $plxml | tr '\n' ' '`"
        lxmlIn=`echo "$plxml" | grep -o -E 'python-lxml-.*?x86_64'`
        zypper -n in $lxmlIn
    else
        echo "python-lxml version is correct." 1>&2
    fi

    checkImageMagick
    if [ "$imCoreInstalledStatus" = "needsUpgraded" ]; then
        magickCore="`ls $scriptdir/suse/x86_64/libMagickCore*`"
        rpm -U $magickCore
    fi
    if [ "$imWandInstalledStatus" = "needsUpgraded" ]; then
        magickwand="`ls $scriptdir/suse/x86_64/libMagickWand*`"
        rpm -U $magickwand
    fi
    if [ "$imInstalledStatus" = "needsUpgraded" ]; then
        imagemagick="`ls $scriptdir/suse/x86_64/ImageMagick*`"
        rpm -U $imagemagick
    fi

# check if yast2-datasync is installed.
    y2=yast2-datasync
    if rpm -qa | grep "$y2" > /dev/null
    then
        uninstall_list=`rpm -qa | grep "$y2"`
        echo "Uninstalling yast2-datasync rpm..."
        uninstall_list="`echo -n $uninstall_list | tr '\n' ' '`"
        rpm -e $uninstall_list
    fi
    if rpm -qa | grep "$y2" > /dev/null
    then
        echo "Failed to uninstall yast2-datasync rpm"
    fi

# install rpms from suse/x86_64/ directory
    echo "Upgrading GMS rpms..."
    rpm -U $scriptdir/suse/x86_64/datasync-*.rpm
#    echo "Check if mobility pack rpms need updating..." 1>&2
#    mpToInstall=`ls $scriptdir/suse/x86_64/datasynchronizer-mobilitypack-release-cd* | awk -F '/' '{print $NF}' | sed -e 's/\.rpm$//'`
#    if rpm -qa | grep "$mpToInstall" > /dev/null
#    then
#        echo "mobility pack rpms are already up to date" 1>&2
#    else
#        echo "Updating mobility pack rpms..." 1>&2
#        rpm -U $scriptdir/suse/x86_64/datasynchronizer*
#    fi

    # Update the services
    checkAndUpdateServices
    updateLogRotateConfiguration

    # Fix python so that dashboard works
    updatePython="False"
    if [ -d /usr/lib64/python2.7 ]
    then
        if [ -f /usr/lib64/python2.7/httplib.py.gms ]
        then
            if grep "if body:" /usr/lib64/python2.7/httplib.py > /dev/null
            then
                echo "python httplib has already been updated." 1>&2
            else
                mv /usr/lib64/python2.7/httplib.py.gms /usr/lib64/python2.7/httplib.py.gms.old
                updatePython="True"
            fi
        else
            updatePython="True"
        fi
        if [ "$updatePython" = "True" ]
        then
            echo "updating python httplib..." 1>&2
            sed -i.gms 's/        self.endheaders(body)/#        self.endheaders(body)\n        if body:\n            self.endheaders(body)\n        else:\n            self.endheaders()/g' /usr/lib64/python2.7/httplib.py
        fi
    fi

} | tee -a $logfile

    /opt/novell/datasync/update.sh "$gwAdminHost" "$gwAdminPort" "$gwAdminUserName" "$gwAdminPassword"
fi

if [ "$ccrEmail" != "" -a "$ccrCode" != "" ]
then
    echo ""
#    echo "**** Still work to do here ... not sure how to register with SLES 12 ****"
#    cmd="suse_register -a regcode-mobility=$ccrCode -a email='$ccrEmail' -L /root/.suse_register.log -d 3"
#    $cmd

#    if [ "$?" != 0 ]
#    then
#        echo "An error was returned while registering GMS with the Novell Customer Center.\n Please run the following command 
# later from the command line to register:\n$cmd"
#    fi
fi

if [ -f $scriptInstallFile ]
then
    # Delete the script.inst file
    rm $scriptInstallFile
fi
{
echo "GMS install complete: $(date)"
} | tee -a $logfile
