#!/bin/bash

### 
# Installation and autoconfigure script for debian'ish systems and dnscrypt.
#
# This script will install pre-req's, make & install dnscrypt and finally set it up
# as a daemon service that runs on system startup. It also gives you the option to
# choose which DNSCrypt service to use and easily reconfigure DNSCrypt and uninstall it.
#
# This script should work on new(er) debian'ish releases.
#
# Author: Simon Clausen <kontakt@simonclausen.dk>
# Version: 0.3
#
# Todo: proper init script, download newest version, handle failed download, fix quirks
#
###

# Are you root?
if [ $(id -u) != 0 ]; then
	echo "Error!"
	echo ""
	echo "You need to be root to run this script."
	exit 1
fi

# Vars for stuff
LSODIUMINST=false
DNSCRYPTINST=false
DNSCRYPTCONF=false
LSODIUMVER=0.4.5
DNSCRYPTVER=1.3.3
WHICHRESOLVER=dnscrypteu

function config_interface {
	echo ""
	echo "Which DNSCrypt service would you like to use?"
	echo ""
	echo "1) DNSCrypt.eu (Europe - no logs, DNSSEC)"
	echo "2) OpenDNS (Anycast)"
	echo "3) CloudNS (Austrailia - no logs, DNSSEC)"
	echo "4) OpenNIC (Japan - no logs)"
	echo "5) OpenNIC (Europe - no logs)"
	echo "6) Soltysiak.com (Europe - no logs, DNSSEC)"
	echo ""
	read -p "Select an option [1-6]: " OPTION
	case $OPTION in
		1)
		WHICHRESOLVER=dnscrypteu
		;;
		2)
		WHICHRESOLVER=opendns
		;;
		3)
		WHICHRESOLVER=cloudns
		;;
		4)
		WHICHRESOLVER=opennicjp
		;;
		5)
		WHICHRESOLVER=openniceu
		;;
		6)
		WHICHRESOLVER=soltysiak
		;;
	esac
	return 0
}

function config_do {
	wget https://raw.github.com/janbrennen/dnscrypt-autoinstall/master/init-scripts/initscript-$WHICHRESOLVER.sh
	if [ $DNSCRYPTCONF == true ]; then
		/etc/init.d/dnscrypt-proxy stop
		update-rc.d -f dnscrypt-proxy remove
		rm /etc/init.d/dnscrypt-proxy
	fi
	mv initscript-$WHICHRESOLVER.sh /etc/init.d/dnscrypt-proxy
	chmod +x /etc/init.d/dnscrypt-proxy
	update-rc.d dnscrypt-proxy defaults
	/etc/init.d/dnscrypt-proxy start
	return 0
}

if [ -e /usr/local/sbin/dnscrypt-proxy ]; then
	DNSCRYPTINST=true
fi

if [ -e /usr/local/lib/libsodium.so ]; then
	LSODIUMINST=true
fi

if [ -e /etc/init.d/dnscrypt-proxy ]; then
	DNSCRYPTCONF=true
fi

if [ $DNSCRYPTINST == true ]; then
	if [ $DNSCRYPTCONF == true ]; then
		echo ""
		echo "Welcome to dnscrypt-autoinstall script."
		echo ""
		echo "It seems like DNSCrypt was installed and configured by this script."
		echo ""
		echo "What would you like to do?"
		echo ""
		echo "1) Configure another DNSCrypt service"
		echo "2) Uninstall DNSCrypt and remove the auto-startup config"
		echo "3) Exit"
		echo ""
		read -p "Select an option [1-3]: " OPTION
		case $OPTION in
			1)
			config_interface
			config_do
			echo "Reconfig done. Quitting."
			exit
			;;
			2)
			/etc/init.d/dnscrypt-proxy stop
			update-rc.d -f dnscrypt-proxy remove
			rm /etc/init.d/dnscrypt-proxy
			rm /usr/local/sbin/dnscrypt-proxy
			deluser dnscrypt
			rm -rf /var/run/dnscrypt
			mv /etc/resolv.conf-dnscryptbak /etc/resolv.conf
			echo "DNSCrypt has been removed. Quitting."
			exit
			;;
			3)
			echo "Bye!"
			exit
			;;
		esac
	else
		echo ""
		echo "Error!"
		echo ""
		echo "It seems like DNSCrypt is already installed but"
		echo "not configured by this script."
		echo ""
		echo "Remove DNSCrypt and it's configuration completely"
		echo "from the system and run this script again."
		echo ""
		echo "Quitting."
		exit 1
	fi
else
	if nc -z -w1 127.0.0.1 53; then
		echo ""
		echo "Error!"
		echo ""
		echo "It looks like there is already a DNS server"
		echo "or forwarder installed and listening on 127.0.0.1."
		echo ""
		echo "To use DNSCypt, you need to either uninstall it"
		echo "or make it listen on another IP than 127.0.0.1."
		echo ""
		echo "Quitting."
		exit 1
	else
		echo ""
		echo "Welcome to dnscrypt-autoinstall script."
		echo ""
		echo "This will install DNSCrypt and autoconfigure it to run as a daemon at start up."
		echo ""
		read -n1 -r -p "Press any key to continue..."
		clear
		echo ""
		echo "Would you like to see a list of supported providers?"
		read -p "(DNSCrypt.eu is default) [y/n]: " -e -i n SHOWLIST
		if [ $SHOWLIST == "y" ]; then
			config_interface
		fi
		
		# Install prereqs and make a working dir
		apt-get update
		apt-get install -y automake libtool build-essential ca-certificates
		cd
		mkdir dnscrypt-autoinstall
		cd dnscrypt-autoinstall
		
		# Is libsodium installed?
		if [ $LSODIUMINST == false ]; then
			# Nope? Then let's get it set up
			wget https://download.libsodium.org/libsodium/releases/libsodium-$LSODIUMVER.tar.gz
			tar -zxf libsodium-$LSODIUMVER.tar.gz
			cd libsodium-$LSODIUMVER
			./configure
			make
			make check
			make install
			ldconfig
			cd ..
		fi
		
		# Continue with dnscrypt installation 
		wget http://download.dnscrypt.org/dnscrypt-proxy/dnscrypt-proxy-$DNSCRYPTVER.tar.gz
		tar -zxf dnscrypt-proxy-$DNSCRYPTVER.tar.gz
		cd dnscrypt-proxy-$DNSCRYPTVER
		./configure
		make
		make install
		cd ..
		
		# Add dnscrypt user and homedir
		mkdir -p /var/run/dnscrypt
		useradd -d /var/run/dnscrypt --system dnscrypt
		chown dnscrypt /var/run/dnscrypt
		
		# Set up init script
		config_do
		
		# Set up resolv.conf to use dnscrypt
		mv /etc/resolv.conf /etc/resolv.conf-dnscryptbak
		echo "nameserver 127.0.0.1" > /etc/resolv.conf
		echo "nameserver 127.0.0.2" >> /etc/resolv.conf
		
		# Clean up
		cd
		rm -rf dnscrypt-autoinstall
	fi
fi
