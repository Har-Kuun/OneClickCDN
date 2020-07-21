#!/bin/bash
#################################################################
#    One-click CDN Installation Script v0.0.2                   #
#    Written by shc (https://qing.su)                           #
#    Github link: https://github.com/Har-Kuun/oneclickCDN       #
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
	echo '*       Version 0.0.1                                             *'
	echo '*       Author: shc (Har-Kuun) https://qing.su                    *'
	echo '*       https://github.com/Har-Kuun/oneclickCDN                   *'
	echo '*       Thank you for using this script.  E-mail: hi@qing.su      *'
	echo '*******************************************************************'
}

function uninstall_ts
{
	current_dir=$(pwd)
	if [ -f ${current_dir}/trafficserver-${TS_VERSION}/configure ] ; then
		cd ${current_dir}/trafficserver-${TS_VERSION}/
		make uninstall
		make distclean
		cd $current_dir
		rm -fr trafficserver-${TS_VERSION}
		rm /etc/systemd/system/trafficserver.service
		systemctl daemon-reload
		echo
		echo "Traffic Server has been uninstalled!"
		echo "Thank you for using this script!"
		echo "Have a nice day!"
		echo 
	else
		wget $TS_DOWNLOAD_LINK
		tar xjf trafficserver-${TS_VERSION}.tar.bz2
		rm trafficserver-${TS_VERSION}.tar.bz2
		cd ${current_dir}/trafficserver-${TS_VERSION}
		./configure
		make uninstall
		make distclean
		cd $current_dir
		rm -fr trafficserver-${TS_VERSION}
		rm /etc/systemd/system/trafficserver.service
		systemctl daemon-reload
		echo
		echo "Traffic Server has been uninstalled!"
		echo "Thank you for using this script!"
		echo "Have a nice day!"
		echo 
	fi
}

function main
{
	display_license
	echo 
	echo "You are about to uninstall Traffic Server CDN."
	echo "This will remove all related configurations as well."
	echo "Please type UNINSTALL to continue.  Type anything else to cancel the uninstallation."
	read do_uninstall
	if [ "x$do_uninstall" = "xUNINSTALL" ] ; then
		uninstall_ts
	else
		echo 
		echo "Traffic Server not uninstalled."
		echo "Have a nice day!"
		echo
	fi
	exit 0
}

main
