#!/bin/bash

# regular colors
    K='\033[0;30m'    # black
    R='\033[0;31m'    # red
    G='\033[0;32m'    # green
    Y='\033[0;33m'    # yellow
    B='\033[0;34m'    # blue
    M='\033[0;35m'    # magenta
    C='\033[0;36m'    # cyan
    W='\033[0;0m'    # white
    BB='\033[1;34m'   # bright blue

# validate ip address function
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

if [ ! "$USER" = "root" ]
then
    echo -e "${R}Please call with root privileges ${W}"  && exit
fi

if [ $# -gt 2 ]
then
    echo -e "${BB}Usage: ./install_OpenNebula.sh (-v) (--client) ${W}" 
    echo -e "${BB}Or: ./install_OpenNebula.sh --remove${W}" && exit
fi
if [ "$1" = "--remove" ]
then
    apt-get remove opennebula 
    apt-get remove opennebula-sunstone
    apt-get remove opennebula-tools
    apt-get remove libopennebula-java-doc
    apt-get remove libopennebula-java 
    apt-get remove ruby-opennebula 
    apt-get remove opennebula-common 
    exit
fi
if [ "$1" = "--client" -o "$2" = "--client" ]
then
    if [ "$1" = "-v" -o "$2" = "-v" ]
    then
       echo -e "${BB}Verbose mode, activated, I will get chatty"

       echo -e "${BB}Installing sshpass"
       apt-get install sshpass || ( echo -e "${R}Install fail: sshpass could not be installed ${W}" && exit )
       read -p "Insert the machine IP to install client: " clientip
       read -p "Insert frontends IP: " ownip
       if valid_ip $clientip;
       then
	   if valid_ip $ownip;
	   then
	   read -p "Insert root password for client: " cliroot
	   echo -e "${BB}Attempting to connect to remote node...${W}"
	   sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'echo -e "${BB}Successfully connected to remote node!${W}"' || ( echo -e "${R}Connect failed${W}" && exit )
	   sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install xen-linux-system-2.6-xen-686' ||  ( echo -e "${R}The Xen install failed ${W}" && exit )
	   sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install xen-tools' || ( echo -e "${R}Could not install xen-tools${W}" && exit )
	   echo -e "${BB}Xen was successfully installed in the remote host!${W}"
	   echo -e "${BB}Will proceed to install opennebula-node in the remote host${W}"
	   sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install opennebula-node' || ( echo -e "${R}Could not install opennebula-node${Ww}" && exit )
	   echo -e "${BB}Installing ssh-server in remote host${W}"
	   sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install openssh-server' || ( echo -e "${R}Install fail: openssh-server could not be installed ${W}" && exit )
	   echo -e "${BB}Generating ssh keys and transferring them to remote host${W}"
	   echo -e "${BB}Specify the file /var/lib/one/.ssh/id_rsa${W}"
	   sudo -u oneadmin ssh-keygen
	   chown oneadmin /var/lib/one/.ssh
	   chown oneadmin /var/lib/one/.ssh/id_rsa.pub
	   chown oneadmin /var/lib/one/.ssh/id_rsa
	   chown oneadmin /var/lib/one/.ssh/authorized_keys
	   chmod 700 /var/lib/one/.ssh
	   chmod 600 /var/lib/one/.ssh/id_rsa.pub
	   chmod 600 /var/lib/one/.ssh/id_rsa
	   chmod 600 /var/lib/one/.ssh/authorized_keys
	   echo -e "${BB}Please configure the config file with StrictHostKeyChecking no${W}"
	   cat /var/lib/one/.ssh/id_rsa.pub >> /var/lib/one/.ssh/authorized_keys
	   echo -e "${BB}The files are now created, please copy them to the remote hosts /var/lib/one/.ssh folder.${W}"
	   read -p "Press enter when done"
	   echo -e "${BB}Transfer complete${W}"
	   echo -e "${BB}Restarting remote ssh server${W}"
	   sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'service ssh restart'
	   else
	   echo -e "${R}Not a valid IP address ${W}" && exit
	   fi
       else
	   echo -e "${R}Not a valid IP address ${W}" && exit
       fi
    else
	apt-get install sshpass || ( echo -e "${R}Install fail: sshpass could not be installed ${W}" && exit )
	read -p "Insert the machine IP to install client: " clientip
	read -p "Insert frontends IP: " ownip
	if valid_ip $clientip;
	then
	    if valid_ip $ownip;
	    then
		read -p "Insert root password for client: " cliroot
		sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install xen-linux-system-2.6-xen-686' ||  ( echo -e "${R}The Xen install failed ${W}" && exit )
		sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install xen-tools' || ( echo -e "${R}Could not install xen-tools${W}" && exit )
		sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install opennebula-node' || ( echo -e "${R}Could not install opennebula-node${Ww}" && exit )
		sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'apt-get install openssh-server' || ( echo -e "${R}Install fail: openssh-server could not be installed ${W}" && exit )
		sudo -u oneadmin ssh-keygen
		chown oneadmin /var/lib/one/.ssh
		chown oneadmin /var/lib/one/.ssh/id_rsa.pub
		chown oneadmin /var/lib/one/.ssh/id_rsa
		chown oneadmin /var/lib/one/.ssh/authorized_keys
		chmod 700 /var/lib/one/.ssh
		chmod 600 /var/lib/one/.ssh/id_rsa.pub
		chmod 600 /var/lib/one/.ssh/id_rsa
		chmod 600 /var/lib/one/.ssh/authorized_keys
		echo -e "${BB}Please configure the config file with StrictHostKeyChecking no${W}"
		cat /var/lib/one/.ssh/id_rsa.pub >> /var/lib/one/.ssh/authorized_keys
		echo -e "${BB}The files are now created, please copy them to the remote hosts /var/lib/one/.ssh folder.${W}"
		sshpass -p "$cliroot" ssh -o StrictHostKeyChecking=no root@${clientip} 'service ssh restart'
	    else
		echo -e "${R}Not a valid IP address ${W}" && exit
	    fi
	else
	    echo -e "${R}Not a valid IP address ${W}" && exit
	fi
    fi
else
    if [ "$1" = "-v" -o "$2" = "-v" ]
    then 
	echo -e "${BB}Verbose mode, activated, I will get chatty"
	
	echo -e "I will install the dependencies for opennebula-common ${W}"
	apt-get install adduser || ( echo -e "${R}Install fail: adduser could not be installed ${W}" && exit )
	apt-get install openssh-client || ( echo -e "${R}Install fail: openssh-client could not be installed ${W}" && exit )
	apt-get install lvm2 || ( echo -e "${R}Install fail: lvm2 could not be installed ${W}" && exit )
	apt-get install sudo || ( echo -e "${R}Install fail: sudo could not be installed ${W}" && exit )
	
	echo -e "${BB}I will proceed to install opennebula-common ${W}"
	apt-get install opennebula-common || ( echo -e "${R}Install fail: opennebula-common could not be installed ${W}" && exit )
	
	echo -e "${BB}I will install the dependencies for ruby-opennebula ${W}"
	apt-get install ruby || ( echo -e "${R}Install fail: ruby could not be installed ${W}" && exit )
	apt-get install ruby-mysql || ( echo -e "${R}Install fail: ruby-mysql could not be installed ${W}" && exit )
	apt-get install ruby-password || ( echo -e "${R}Install fail: ruby-password could not be installed ${W}" && exit )
	apt-get install ruby-sequel || ( echo -e "${R}Install fail: ruby-sequel could not be installed ${W}" && exit )
	apt-get install ruby-sqlite3 || ( echo -e "${R}Install fail: ruby-sqlite3 could not be installed ${W}" && exit )
	apt-get install rubygems || ( echo -e "${R}Install fail: rubygems could not be installed ${W}" && exit )
	
	echo -e "${BB}I will proceed to install ruby-opennebula ${W}"
	apt-get install ruby-opennebula || ( echo -e "${R}Install fail: ruby-opennebula could not be installed ${W}" && exit )
	
	echo -e "${BB}We are almost there, I will install libopennebula-java and libopennebula-java-doc ${W}"
	apt-get install libopennebula-java || ( echo -e "${R}Install fail: libopennebula-java could not be installed ${W}" && exit )
	apt-get install libopennebula-java-doc || ( echo -e "${R}Install fail: libopennebula-java-doc could not be installed ${W}" && exit )
	
	echo -e "${BB}So far, so good. I will now install opennebula-tools! ${W}"
	apt-get install opennebula-tools || ( echo -e "${R}Install fail: opennebula-tools could not be installed ${W}" && exit )
	
	echo -e "${BB}Be patient, I shall install the dependencies for opennebula-sunstone ${W}"
	apt-get install libjs-jquery || ( echo -e "${R}Install fail: libjs-jquery could not be installed ${W}" && exit )
	apt-get install libjs-jquery-ui || ( echo -e "${R}Install fail: libjs-jquery-ui could not be installed ${W}" && exit )
	apt-get install ruby-json || ( echo -e "${R}Install fail: ruby-json could not be installed ${W}" && exit )
	apt-get install ruby-sinatra || ( echo -e "${R}Install fail: ruby-sinatra could not be installed ${W}" && exit )
	apt-get install thin1.8 || ( echo -e "${R}Install fail: thin1.8 could not be installled ${W}" && exit )
	apt-get install novnc || ( echo -e "${R}Install fail: novnc could not be installed ${W}" && exit )
	
	echo -e "${BB}I will install opennebula-sunstone ${W}"
	apt-get install opennebula-sunstone || ( echo -e "${R}Install fail: opennebula-sunstone could not be installed ${W}" && exit )
	
	echo -e "${BB}I will install the dependencies for opennebula, go get an orange juice or something ${W}"
	apt-get install apg || ( echo -e "${R}Install fail: apg could not be installed ${W}" && exit )
	apt-get install genisoimage || ( echo -e "${R}Install fail: genisoimage could not be installed ${W}" && exit )
	apt-get install tzdata || ( echo -e "${R}Install fail: tzdata could not be installed ${W}" && exit )
	apt-get install libc-bin || ( echo -e "${R}Install fail: libc-bin could not be installed ${W}" && exit )
	apt-get install initscripts || ( echo -e "${R}Install fail: initscripts could not be installed ${W}" && exit )
	apt-get install libc6 || ( echo -e "${R}Install fail: libc6 could not be installed ${W}" && exit )
	apt-get install libdb1-compat || ( echo -e "${R}Install fail: libdb1-compat could not be installed ${W}" && exit )
	apt-get install libgcc1 || ( echo -e "${R}Install fail: libgcc1 could not be installed ${W}" && exit )
	apt-get install libmysqlclient18 || ( echo -e "${R}Install fail: libmysqlclien18 could not be installed ${W}" && exit )
	apt-get install libsqlite3-0 || ( echo -e "${R}Install fail: libsqlite3-0 could not be installed ${W}" && exit )
	apt-get install libssl1.0.0 || ( echo -e "${R}Install fail: libssl1.0.0 could not be installed ${W}" && exit )
	apt-get install libstdc++6 || ( echo -e "${R}Install fail: libstdc++6 could not be installed ${W}" && exit )
	apt-get install libunwind7 || ( echo -e "${R}Install fail: libunwind7 could not be installed ${W}" && exit )
	apt-get install libxml2 || ( echo -e "${R}Install fail: libxml2 could not be installed ${W}" && exit )
	apt-get install libxmlrpc-c++4 || ( echo -e "${R}Install fail: libxmlrpc-c++ could not be installed ${W}" && exit )
	apt-get install libxmlrpc-core-c3 || ( echo -e "${R}Install fail: libxmlrpc-core-c3 could not be installed ${W}" && exit )
	apt-get install wget || ( echo -e "${R}Install fail: wget could not be installed ${W}" && exit )
	apt-get install mysql-server || ( echo -e "${R}Install fail: mysql-server could not be installed ${W}" && exit )
	apt-get install ruby-amazon-ec2 || ( echo -e "${R}Install fail: ruby-amazon-ec2 could not be installed ${W}" && exit )
	apt-get install ruby-uuidtools || ( echo -e "${R}Install fail: ruby-uuidtools could not be installed ${W}" && exit )
	
	echo -e "${BB}I will install opennebula ${W}"
	apt-get install opennebula || ( echo -e "${R}Install fail: opennebula could not be installed ${W}" && exit )
	
	echo -e "${BB}Hurray! Install success! ${W}"
    fi

    if [ "$#" = "0" ]
    then
	echo -e "${BB}Installing... ${W}"
	touch /tmp/file
	apt-get install adduser &> /tmp/file || ( echo -e "${R}Install fail: adduser could not be installed ${W}" && exit ) &> /tmp/file
	apt-get install openssh-client &> /tmp/file || ( echo -e "${R}Install fail: openssh-client could not be installed ${W}" && exit ) &> /tmp/file
	apt-get install lum2 &> /tmp/file  || ( echo -e "${R}Install fail: lum2 could not be installed ${W}" && exit ) &> /tmp/file
	apt-get install sudo &> /tmp/file || ( echo -e "${R}Install fail: sudo could not be installed ${W}" && exit ) &> /tmp/file
	apt-get install opennebula-common &> /tmp/file || ( echo -e "${R}Install fail: opennebula-common could not be installed ${W}" && exit ) &> /tmp/file
	apt-get install ruby &> /tmp/file || ( echo -e "${R}Install fail: ruby could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-mysql &> /tmp/file || ( echo -e "${R}Install fail: ruby-mysql could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-password &> /tmp/file || ( echo -e "${R}Install fail: ruby-password could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-sequel &> /tmp/file || ( echo -e "${R}Install fail: ruby-sequel could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-sqlite3 &> /tmp/file || ( echo -e "${R}Install fail: ruby-sqlite3 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install rubygems &> /tmp/file || ( echo -e "${R}Install fail: rubygems could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-opennebula  &> /tmp/file || ( echo -e "${R}Install fail: ruby-opennebula could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libopennebula-java  &> /tmp/file || ( echo -e "${R}Install fail: libopennebula-java could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libopennebula-java-doc  &> /tmp/file || ( echo -e "${R}Install fail: libopennebula-java-doc could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install opennebula-tools  &> /tmp/file || ( echo -e "${R}Install fail: opennebula-tools could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libjs-jquery  &> /tmp/file || ( echo -e "${R}Install fail: libjs-jquery could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libjs-jquery-ui  &> /tmp/file || ( echo -e "${R}Install fail: libjs-jquery-ui could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-json  &> /tmp/file || ( echo -e "${R}Install fail: ruby-json could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-sinatra  &> /tmp/file || ( echo -e "${R}Install fail: ruby-sinatra could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install thin1.8  &> /tmp/file || ( echo -e "${R}Install fail: thin1.8 could not be installled ${W}" && exit ) &> /tmp/file 
	apt-get install novnc  &> /tmp/file || ( echo -e "${R}Install fail: novnc could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install opennebula-sunstone  &> /tmp/file || ( echo -e "${R}Install fail: opennebula-sunstone could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install apg  &> /tmp/file || ( echo -e "${R}Install fail: apg could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install genisoimage &> /tmp/file || ( echo -e "${R}Install fail: genisoimage could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install tzdata  &> /tmp/file || ( echo -e "${R}Install fail: tzdata could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libc-bin  &> /tmp/file || ( echo -e "${R}Install fail: libc-bin could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install initscripts  &> /tmp/file || ( echo -e "${R}Install fail: initscripts could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libc6  &> /tmp/file || ( echo -e "${R}Install fail: libc6 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libdb1-compat  &> /tmp/file || ( echo -e "${R}Install fail: libdb1-compat could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libgcc1  &> /tmp/file || ( echo -e "${R}Install fail: libgcc1 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libmysqlclient18  &> /tmp/file || ( echo -e "${R}Install fail: libmysqlclien18 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libsqlite3-0  &> /tmp/file || ( echo -e "${R}Install fail: libsqlite3-0 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libssl1.0.0  &> /tmp/file || ( echo -e "${R}Install fail: libssl1.0.0 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libstdc++6  &> /tmp/file || ( echo -e "${R}Install fail: libstdc++6 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libunwind7  &> /tmp/file || ( echo -e "${R}Install fail: libunwind7 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libxml2  &> /tmp/file || ( echo -e "${R}Install fail: libxml2 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libxmlrpc-c++4  &> /tmp/file || ( echo -e "${R}Install fail: libxmlrpc-c++ could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install libxmlrpc-core-c3  &> /tmp/file || ( echo -e "${R}Install fail: libxmlrpc-core-c3 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install wget  &> /tmp/file || ( echo -e "${R}Install fail: wget could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install mysql-server  &> /tmp/file || ( echo -e "${R}Install fail: mysql-server could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-amazon-ec2  &> /tmp/file || ( echo -e "${R}Install fail: ruby-amazon-ec2 could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install ruby-uuidtools  &> /tmp/file || ( echo -e "${R}Install fail: ruby-uuidtools could not be installed ${W}" && exit ) &> /tmp/file 
	apt-get install opennebula  &> /tmp/file || ( echo -e "${R}Install fail: opennebula could not be installed ${W}" && exit ) &> /tmp/file
	echo -e "${BB}Install complete! ${W}"
    fi
fi 

if [ -f /tmp/file ]
then
    rm /tmp/file
fi
