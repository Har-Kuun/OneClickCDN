#!/bin/bash
#################################################################
#    Configuration Backup and Restore Tool for OneClickCDN      #
#    Written by shc (https://qing.su)                           #
#    Github link: https://github.com/Har-Kuun/OneClickCDN       #
#    Contact me: https://t.me/hsun94   E-mail: hi@qing.su       #
#                                                               #
#    This script is distributed in the hope that it will be     #
#    useful, but it comes WITHOUT ANY WARRANTY.                 #
#                                                               #
#    Thank you for using this script.                           #
#################################################################

CurrentDir=$(pwd)

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

function check_TS
{
	if [ -f /usr/local/bin/trafficserver ] ; then
		TS_INSTALLED=1
	else
		TS_INSTALLED=0
		say "You don't seem to have OneClickCDN installed." red
		exit 1
	fi
}

function display_license
{
	echo 
	echo '*******************************************************************'
	echo '*      Configuration Backup and Restore Tool for OneClickCDN      *'
	echo '*      Version 0.0.1                                              *'
	echo '*      Author: shc (Har-Kuun) https://qing.su                     *'
	echo '*      https://github.com/Har-Kuun/OneClickDesktop                *'
	echo '*      Thank you for using this script.  E-mail: hi@qing.su       *'
	echo '*******************************************************************'
	echo 
}

function backupConfiguration
{
	echo 
	say @B"Backing up Trafficserver configurations..." yellow
	BackupFileName=OneClickCDN$(date +"%Y%m%d").tar.gz
	tar zcf $CurrentDir/$BackupFileName /usr/local/etc/trafficserver
	sleep 1
	cd /tmp && tar zxf $CurrentDir/$BackupFileName
	if [ -f /tmp/usr/local/etc/trafficserver/records.config ] ; then
		say @B"Configuration successfully backed up at $CurrentDir/$BackupFileName" green
		echo 
	else
		say "Backup failed.  Please try again." red
		echo 
	fi
}

function restoreBackup_localFile
{
	echo 
	say @B"Please input path to your Trafficserver configuration backup file, ending in .tar.gz" yellow
	read backupFilePath
	if [ -f $backupFilePath ] ; then
		echo 
		say @B"Restoring backup..." green
		tar zcf $CurrentDir/OneClickCDN$(date +"%Y%m%d").tar.gz /usr/local/etc/trafficserver
		cd /tmp && tar zxf $backupFilePath
		cd /usr/local/etc/trafficserver && rm -fr *
		cp -rf /tmp/usr/local/etc/trafficserver/* .
		sleep 2
		if [ -f /usr/local/etc/trafficserver/records.config ] ; then
			say @B"Configuration successfully restored from backup file." green
			/usr/local/bin/trafficserver restart
			echo 
		else
			say "Failed to restore configuration file from backup.  Please try again." red
			echo 
		fi
	else
		say "Cannot find Trafficserver configuration backup file.  Please try again." red
		echo 
	fi
}

function restoreBackup_onlineFile
{
	echo 
	say @B"Please input URL (including https:// or http://) of your Trafficserver configuration backup file, ending in .tar.gz" yellow
	read backupFileURL
	echo 
	cd /tmp && d_status=$(curl -sw '%{http_code}' $backupFileURL -o OneClickCDNRestore_tmp.tar.gz)
	if [ "$d_status" = "200" ] ; then
		echo 
		say @B"Restoring backup..." green
		tar zcf $CurrentDir/OneClickCDN$(date +"%Y%m%d").tar.gz /usr/local/etc/trafficserver
		cd /tmp && tar zxf OneClickCDNRestore_tmp.tar.gz
		cd /usr/local/etc/trafficserver && rm -fr *
		cp -rf /tmp/usr/local/etc/trafficserver/* .
		sleep 2
		if [ -f /usr/local/etc/trafficserver/records.config ] ; then
			say @B"Configuration successfully restored from backup file." green
			/usr/local/bin/trafficserver restart
			echo 
		else
			say "Failed to restore configuration file from backup.  Please check your backup file." red
			echo 
		fi
	else
		say "Download error $d_status.  Please check and try again." red
		echo 
	fi
}

function main
{
	display_license
	check_TS
	say @B"Please type 1 to backup your configuration files, type 2 to restore backup from local disk, or type 3 to restore backup from Internet." yellow
	read choice
	case $choice in 
		1 ) backupConfiguration ;;
		2 ) restoreBackup_localFile ;;
		3 ) restoreBackup_onlineFile ;;
		* ) say @B"OK, Bye." green ;;
	esac
	echo 
	say @B"Thank you for using this backup script.  Have a nice day!" green
	echo 
}

main
