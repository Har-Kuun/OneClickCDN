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

#This script is used to translate the original OneClickCDN script into other languages.
#Please copy the template file and rename it to your language code, e.g., zh-CN or es.
#The renamed file will be your language file.  You should put the translated text after the `|` symbol.
#After you finish translation, run this script to generate the translated OneClickCDN script.

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

echo 
say @B"Please input path to the original OneClickCDN script file:" yellow
read original_script
say @B"Please input path to the language file:" yellow
read language_file
echo 

#Extract language code from language file name.
language_symbol=$(basename $language_file)

#Extract output location for translated script.
translated_script=$(echo "$original_script" | sed -e 's/\.[^.]*$//')_$language_symbol.sh
cp $original_script $translated_script

#Check for some common errors.
if [ ! -f $language_file ] ; then
	say "Language file does not exist." red
	exit 1
elif [ ! -f $translated_script ] ; then
	say "Error processing original script." red
	say "The original script must be stored in a directory that you have write permission." red
	exit 1
fi

#Translate the script.
while read line; do
	if [ "x$line" = "x" ] ; then
		continue
	fi
	read original_text <<< $(echo "$line" | awk -F'|' '{print $1}')
	read translated_text <<< $(echo "$line" | awk -F'|' '{print $2}')
	if [ "x$translated_text" = "x" ] || [ "x$original_text" = "x" ] ; then
		continue
	fi
	sed -i "s#$original_text#$translated_text#g" $translated_script
done < $language_file

echo 
say @B"Translation completed!" green
say @B"Translated script is saved at ${translated_script}!" green
echo 
echo "Thank you for using this script!  Have a nice day!"
echo 
