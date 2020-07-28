#!/bin/bash
#################################################################
#    One-click CDN Installation Script v0.0.4                   #
#    Written by shc (https://qing.su)                           #
#    Github link: https://github.com/Har-Kuun/OneClickCDN       #
#    Contact me: https://t.me/hsun94   E-mail: hi@qing.su       #
#                                                               #
#    This script is distributed in the hope that it will be     #
#    useful, but ABSOLUTELY WITHOUT ANY WARRANTY.               #
#                                                               #
#    Thank you for using this script.                           #
#################################################################


#You can change the Traffic Server source file download link here.
#If you changed the download link when installing the script, please also change the link here to match the Traffic Server version you installed.
#If you did not change the download link during the installation, simply leave it as is.

TS_DOWNLOAD_LINK="https://mirrors.ocf.berkeley.edu/apache/trafficserver/trafficserver-8.0.8.tar.bz2"
TS_VERSION="8.0.8"


#########################################################################
#    Functions start here.                                              #
#    Do not change anything below unless you know what you are doing.   #
#########################################################################


function display_license
{
	echo 
	echo '*******************************************************************'
	echo '*       One-click CDN installation script                         *'
	echo '*       Version 0.0.4                                             *'
	echo '*       Author: shc (Har-Kuun) https://qing.su                    *'
	echo '*       https://github.com/Har-Kuun/OneClickCDN                   *'
	echo '*       Thank you for using this script.  E-mail: hi@qing.su      *'
	echo '*******************************************************************'
}

function say
{
#This function is a colored version of the built-in "echo."
#https://github.com/Har-Kuun/useful-shell-functions/blob/master/colored-echo.sh
	echo_content=$1
	case $2 in
		black | k ) colorf=0 ;;
		red | r ) colorf=1 ;;
		green | g ) colorf=2 ;;
		yellow | y ) colorf=3 ;;
		blue | b ) colorf=4 ;;
		magenta | m ) colorf=5 ;;
		cyan | c ) colorf=6 ;;
		white | w ) colorf=7 ;;
		* ) colorf=N ;;
	esac
	case $3 in
		black | k ) colorb=0 ;;
		red | r ) colorb=1 ;;
		green | g ) colorb=2 ;;
		yellow | y ) colorb=3 ;;
		blue | b ) colorb=4 ;;
		magenta | m ) colorb=5 ;;
		cyan | c ) colorb=6 ;;
		white | w ) colorb=7 ;;
		* ) colorb=N ;;
	esac
	if [ "x${colorf}" != "xN" ] ; then
		tput setaf $colorf
	fi
	if [ "x${colorb}" != "xN" ] ; then
		tput setab $colorb
	fi
	printf "${echo_content}" | sed -e "s/@B/$(tput bold)/g"
	tput sgr 0
	printf "\n"
}

function uninstall_ts
{
	current_dir=$(pwd)
	if [ -f ${current_dir}/trafficserver-${TS_VERSION}/configure ] ; then
		cd ${current_dir}/trafficserver-${TS_VERSION}/
	else
		wget $TS_DOWNLOAD_LINK
		tar xjf trafficserver-${TS_VERSION}.tar.bz2
		rm trafficserver-${TS_VERSION}.tar.bz2
		cd ${current_dir}/trafficserver-${TS_VERSION}
		./configure
	fi
		make uninstall
		make distclean
		cd $current_dir
		rm -fr trafficserver-${TS_VERSION}
		rm -f /etc/systemd/system/trafficserver.service
		rm -fr /etc/trafficserver
		rm -fr /usr/local/etc/trafficserver
		systemctl daemon-reload
		echo
		say @B"Traffic Server has been uninstalled!" green
		echo "Thank you for using this script!"
		echo "Have a nice day!"
		echo 
}

function main
{
	display_license
	echo 
	if [ ! -f /usr/local/bin/trafficserver ] ; then
		say @B"Traffic server is NOT installed." red
		echo 
		exit 1
	fi
	echo "You are about to uninstall Traffic Server CDN."
	echo "This will remove all related configurations as well."
	say "Please type UNINSTALL to continue.\nType anything else to cancel the uninstallation." yellow blue
	read do_uninstall
	if [ "x$do_uninstall" = "xUNINSTALL" ] ; then
		uninstall_ts
	else
		echo 
		say @B"Traffic Server not uninstalled." blue
		echo "Have a nice day!"
		echo
	fi
	exit 0
}

main
