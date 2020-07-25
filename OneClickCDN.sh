#!/bin/bash
#################################################################
#    One-click CDN Installation Script v0.0.3                   #
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
#Check https://www.apache.org/dyn/closer.cgi/trafficserver for the latest stable version.

TS_DOWNLOAD_LINK="https://mirrors.ocf.berkeley.edu/apache/trafficserver/trafficserver-8.0.8.tar.bz2"
TS_VERSION="8.0.8"



#You can enable an experimental feature: reverse proxy for any website.
#Please note that this feature is kind of buggy; you might have to manually modify some mapping rules if necessary.
#If you wish to turn on this feature, set the value for the variable below to ON, and use the special key in the main function to add reverse proxy instances.

REVERSE_PROXY_MODE_ENABLED=OFF



#By default, this script only works on Ubuntu 20, Debian 10, and CentOS 7/8.
#You can disable the OS check switch below and tweak the code yourself to try to install it in other OS versions.
#Please do note that if you choose to use this script on OS other than Ubuntu 20, Debian 10, or CentOS 7/8, you might mess up your OS.  Please keep a backup of your server before installation.

OS_CHECK_ENABLED=ON







#########################################################################
#    Functions start here.                                              #
#    Do not change anything below unless you know what you are doing.   #
#########################################################################

function check_OS
{
	if [ -f /etc/lsb-release ]
	then
		cat /etc/lsb-release | grep "DISTRIB_RELEASE=18." >/dev/null
		if [ $? = 0 ]
		then
			OS=UBUNTU18
			echo "Support of Ubuntu 18 is experimental.  You may get error in TLS handshakes."
			echo "Please consider upgrading to Ubuntu 20 (simply run \"do-release-upgrade -d\")."
			echo "Please tweak the OS_CHECK_ENABLED setting if you still wish to install on Ubuntu 18."
			echo 
			exit 1
		else
			cat /etc/lsb-release | grep "DISTRIB_RELEASE=20." >/dev/null
			if [ $? = 0 ]
			then
				OS=UBUNTU20
			else
				echo "Sorry, this script only supports Ubuntu 20 and Debian 10."
				echo 
				exit 1
			fi
		fi
	elif [ -f /etc/debian_version ] ; then
		cat /etc/debian_version | grep "^10." >/dev/null
		if [ $? = 0 ] ; then
			OS=DEBIAN10
			echo "Support of Debian 10 is experimental.  Please report bugs."
			echo 
		else
			cat /etc/debian_version | grep "^9." >/dev/null
			if [ $? = 0 ] ; then
				OS=DEBIAN9
				echo "Support of Debian 9 is experimental.  You may get error in TLS handshakes."
				echo "Please tweak the OS_CHECK_ENABLED setting if you still wish to install on Debian 9."
				echo 
				exit 1
			else
				echo "Sorry, this script only supports Ubuntu 20 and Debian 10."
				echo 
				exit 1
			fi
		fi
	elif [ -f /etc/redhat-release ] ; then
		cat /etc/redhat-release | grep " 8." >/dev/null
		if [ $? = 0 ] ; then
			OS=CENTOS8
			echo "Support of CentOS 8 is experimental.  Please report bugs."
			echo "Please try disabling selinux or firewalld if you cannot visit your website."
			echo 
		else
			cat /etc/redhat-release | grep " 7." >/dev/null
			if [ $? = 0 ] ; then
				OS=CENTOS7
				echo "Support of CentOS 7 is experimental.  Please report bugs."
				echo "Please try disabling selinux or firewalld if you cannot visit your website."
				echo 
			else
				echo "Sorry, this script only supports Ubuntu 20, Debian 10, and CentOS 7/8."
				echo
				exit 1
			fi
		fi
	else
		echo "Sorry, this script only supports Ubuntu 20, Debian 10, and CentOS 7/8."
		echo 
		exit 1
	fi
}

function check_TS
{
	if [ -f /usr/local/bin/trafficserver ] ; then
		TS_INSTALLED=1
	else
		TS_INSTALLED=0
	fi
}


function install_TS
{
	echo "Starting Traffic Server installation..."
	echo "..."
	echo "..."
	echo "Removing Nginx and Apache..."
	apt-get remove nginx apache -y
	echo "Installing depedencies..."
	apt-get update && apt-get upgrade -y
	apt-get install wget curl tar certbot automake libtool pkg-config libmodule-install-perl gcc g++ libssl-dev tcl-dev libpcre3-dev libcap-dev libhwloc-dev libncurses5-dev libcurl4-openssl-dev flex autotools-dev bison debhelper dh-apparmor gettext intltool-debian libbison-dev libexpat1-dev libfl-dev libsigsegv2 libsqlite3-dev m4 po-debconf tcl8.6-dev zlib1g-dev -y
	wget $TS_DOWNLOAD_LINK
	tar xjf trafficserver-${TS_VERSION}.tar.bz2
	rm -f trafficserver-${TS_VERSION}.tar.bz2
	cd ${current_dir}/trafficserver-${TS_VERSION}
	echo "Start building Traffic Server from source..."
	./configure --enable-experimental-plugins
	if [ -f ${current_dir}/trafficserver-${TS_VERSION}/config.status ] ; then
		echo "Dependencies met!"
		echo "Compiling now..."
		echo
	else
		echo 
		echo "Missing dependencies."
		echo "Please check log, install required dependencies, and run this script again."
		echo "Please also consider to report your log here https://github.com/Har-Kuun/OneClickCDN/issues so that I can fix this issue."
		echo "Thank you!"
		echo 
		exit 1
	fi
	make
	make install
	if [ -f /usr/local/bin/traffic_manager ] ; then
		echo 
		echo "Traffic Server successfully installed!"
		echo
	else
		echo
		echo "Traffic Server installation failed."
		echo "Please check the above log for reasons."
		echo "Please also consider to report your log here https://github.com/Har-Kuun/OneClickCDN/issues so that I can fix this issue."
		echo "Thank you!"
		echo
		exit 1
	fi
	ln -s /usr/local/etc/trafficserver /etc/trafficserver
	mkdir /etc/trafficserver/ssl
	chown nobody /etc/trafficserver/ssl
	chmod 0760 /etc/trafficserver/ssl
	cd ${current_dir}
	ldconfig
	trafficserver start
	echo 
	echo "Traffic Server successfully installed!"
	echo "Domain		Type(CDN/RevProxy)		OriginIP" > /etc/trafficserver/hostsavailable.sun
#	echo "trafficserver start" >> /etc/rc.local
	run_on_startup
	echo 
}

function install_TS_CentOS
{
	echo "Starting Traffic Server installation..."
	echo "..."
	echo "..."
	echo "Removing Nginx and Apache..."
	yum remove httpd nginx -y
	echo "Installing depedencies..."
	yum update -y
	if [ "x$OS" = "xCENTOS7" ] ; then
		yum install centos-release-scl -y
		yum install devtoolset-8 -y
		scl enable devtoolset-8
		yum install wget curl tar openssl-devel pcre-devel tcl-devel gcc-c++ expat-devel libcap-devel hwloc ncurses-devel libcurl-devel pcre-devel tcl-devel expat-devel openssl-devel perl-ExtUtils-MakeMaker bzip2 -y
		yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
		yum install certbot -y
		source /opt/rh/devtoolset-8/enable
	else
		dnf -y group install "Development Tools"
		dnf -y install wget curl tar openssl-devel pcre-devel tcl-devel expat-devel libcap-devel hwloc ncurses-devel bzip2 libcurl-devel pcre-devel tcl-devel expat-devel openssl-devel perl-ExtUtils-MakeMaker
		yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
		dnf -y install certbot
		dnf config-manager --set-enabled PowerTools		
	fi
	wget $TS_DOWNLOAD_LINK
	tar xjf trafficserver-${TS_VERSION}.tar.bz2
	rm -f trafficserver-${TS_VERSION}.tar.bz2
	cd ${current_dir}/trafficserver-${TS_VERSION}
	echo "Start building Traffic Server from source..."
	./configure --enable-experimental-plugins
	if [ -f ${current_dir}/trafficserver-${TS_VERSION}/config.status ] ; then
		echo "Dependencies met!"
		echo "Compiling now..."
		echo
	else
		echo 
		echo "Missing dependencies."
		echo "Please check log, install required dependencies, and run this script again."
		echo "Please also consider to report your log here https://github.com/Har-Kuun/OneClickCDN/issues so that I can fix this issue."
		echo "Thank you!"
		echo 
		exit 1
	fi
	make
	make install
	if [ -f /usr/local/bin/traffic_manager ] ; then
		echo 
		echo "Traffic Server successfully installed!"
		echo
	else
		echo
		echo "Traffic Server installation failed."
		echo "Please check the above log for reasons."
		echo "Please also consider to report your log here https://github.com/Har-Kuun/OneClickCDN/issues so that I can fix this issue."
		echo "Thank you!"
		echo
		exit 1
	fi
	ln -s /usr/local/etc/trafficserver /etc/trafficserver
	mkdir /etc/trafficserver/ssl
	chown nobody /etc/trafficserver/ssl
	chmod 0760 /etc/trafficserver/ssl
	cd ${current_dir}
	ldconfig
	trafficserver start
	echo 
	echo "Traffic Server successfully installed!"
	echo "Domain		Type(CDN/RevProxy)		OriginIP" > /etc/trafficserver/hostsavailable.sun
	run_on_startup
	echo 
}

function config_main_records
{
	cat > /etc/trafficserver/records.config <<END
CONFIG proxy.config.exec_thread.autoconfig INT 1
CONFIG proxy.config.exec_thread.autoconfig.scale FLOAT 1.5
CONFIG proxy.config.exec_thread.limit INT 2
CONFIG proxy.config.accept_threads INT 1
CONFIG proxy.config.task_threads INT 2
CONFIG proxy.config.cache.threads_per_disk INT 8
CONFIG proxy.config.exec_thread.affinity INT 1
CONFIG proxy.config.http.server_ports STRING 80 443:proto=http2;http:ssl
CONFIG proxy.config.http.insert_request_via_str INT 1
CONFIG proxy.config.http.insert_response_via_str INT 2
CONFIG proxy.config.http.response_via_str STRING ATS
CONFIG proxy.config.http.parent_proxy_routing_enable INT 0
CONFIG proxy.config.http.parent_proxy.retry_time INT 300
CONFIG proxy.config.http.parent_proxy.connect_attempts_timeout INT 30
CONFIG proxy.config.http.forward.proxy_auth_to_parent INT 0
CONFIG proxy.config.http.uncacheable_requests_bypass_parent INT 1
CONFIG proxy.config.http.keep_alive_no_activity_timeout_in INT 120
CONFIG proxy.config.http.keep_alive_no_activity_timeout_out INT 120
CONFIG proxy.config.http.transaction_no_activity_timeout_in INT 30
CONFIG proxy.config.http.transaction_no_activity_timeout_out INT 30
CONFIG proxy.config.http.transaction_active_timeout_in INT 900
CONFIG proxy.config.http.transaction_active_timeout_out INT 0
CONFIG proxy.config.http.accept_no_activity_timeout INT 120
CONFIG proxy.config.net.default_inactivity_timeout INT 86400
CONFIG proxy.config.http.connect_attempts_max_retries INT 3
CONFIG proxy.config.http.connect_attempts_max_retries_dead_server INT 1
CONFIG proxy.config.http.connect_attempts_rr_retries INT 3
CONFIG proxy.config.http.connect_attempts_timeout INT 30
CONFIG proxy.config.http.post_connect_attempts_timeout INT 1800
CONFIG proxy.config.http.down_server.cache_time INT 60
CONFIG proxy.config.http.down_server.abort_threshold INT 10
CONFIG proxy.config.http.negative_caching_enabled INT 0
CONFIG proxy.config.http.negative_caching_lifetime INT 1800
CONFIG proxy.config.http.insert_client_ip INT 1
CONFIG proxy.config.http.insert_squid_x_forwarded_for INT 1
CONFIG proxy.config.http.push_method_enabled INT 0
CONFIG proxy.config.http.cache.http INT 1
CONFIG proxy.config.http.cache.ignore_client_cc_max_age INT 1
CONFIG proxy.config.http.normalize_ae INT 1
CONFIG proxy.config.http.cache.cache_responses_to_cookies INT 1
CONFIG proxy.config.http.cache.when_to_revalidate INT 0
CONFIG proxy.config.http.cache.required_headers INT 2
CONFIG proxy.config.http.cache.ignore_client_no_cache INT 1
CONFIG proxy.config.http.cache.heuristic_min_lifetime INT 3600
CONFIG proxy.config.http.cache.heuristic_max_lifetime INT 86400
CONFIG proxy.config.http.cache.heuristic_lm_factor FLOAT 0.10
CONFIG proxy.config.net.connections_throttle INT 30000
CONFIG proxy.config.net.max_connections_in INT 30000
CONFIG proxy.config.net.max_connections_active_in INT 10000
CONFIG proxy.config.cache.ram_cache_cutoff INT 4194304
CONFIG proxy.config.cache.limits.http.max_alts INT 5
CONFIG proxy.config.cache.max_doc_size INT 0
CONFIG proxy.config.cache.min_average_object_size INT 8000
CONFIG proxy.config.log.logging_enabled INT 3
CONFIG proxy.config.log.max_space_mb_for_logs INT 25000
CONFIG proxy.config.log.max_space_mb_headroom INT 1000
CONFIG proxy.config.log.rolling_enabled INT 1
CONFIG proxy.config.log.rolling_interval_sec INT 86400
CONFIG proxy.config.log.rolling_size_mb INT 10
CONFIG proxy.config.log.auto_delete_rolled_files INT 1
CONFIG proxy.config.log.periodic_tasks_interval INT 5
CONFIG proxy.config.url_remap.remap_required INT 1
CONFIG proxy.config.url_remap.pristine_host_hdr INT 1
CONFIG proxy.config.reverse_proxy.enabled INT 1
CONFIG proxy.config.ssl.client.verify.server INT 0
CONFIG proxy.config.ssl.client.CA.cert.filename STRING NULL
CONFIG proxy.config.ssl.server.cipher_suite STRING ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-DSS-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-DSS-AES256-SHA:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
CONFIG proxy.config.diags.debug.enabled INT 0
CONFIG proxy.config.diags.debug.tags STRING http|dns
CONFIG proxy.config.dump_mem_info_frequency INT 0
CONFIG proxy.config.http.slow.log.threshold INT 0
CONFIG proxy.config.ssl.server.cert.path STRING /etc/trafficserver/ssl/
CONFIG proxy.config.ssl.server.private_key.path STRING /etc/trafficserver/ssl/
CONFIG proxy.config.cache.enable_read_while_writer INT 1
CONFIG proxy.config.http.background_fill_active_timeout INT 0
CONFIG proxy.config.http.background_fill_completed_threshold FLOAT 0.000000
CONFIG proxy.config.cache.max_doc_size INT 0
CONFIG proxy.config.cache.read_while_writer.max_retries INT 10
CONFIG proxy.config.cache.read_while_writer_retry.delay INT 50
CONFIG proxy.config.http.congestion_control.enabled INT 1
CONFIG proxy.config.http.cache.max_open_read_retries INT 5
CONFIG proxy.config.http.cache.open_read_retry_time INT 10
CONFIG proxy.config.cache.ram_cache.compress INT 1
CONFIG proxy.config.ssl.ocsp.enabled INT 1

END
}

function config_cache_rules
{
	cat > /etc/trafficserver/cache.config <<END
url_regex=.* suffix=xml  ttl-in-cache=5d
url_regex=.* suffix=ts  ttl-in-cache=5d
url_regex=.* suffix=jpeg  ttl-in-cache=5d
url_regex=.* suffix=mp4  ttl-in-cache=5d
url_regex=.* suffix=zip  ttl-in-cache=5d
url_regex=.* suffix=gif  ttl-in-cache=5d
url_regex=.* suffix=ppt  ttl-in-cache=5d
url_regex=.* suffix=jpg  ttl-in-cache=5d
url_regex=.* suffix=swf  ttl-in-cache=5d
url_regex=.* scheme=https ttl-in-cache=1h
url_regex=.* scheme=http  ttl-in-cache=1h
url_regex=.* suffix=m3u8  ttl-in-cache=5d
url_regex=.* suffix=js  ttl-in-cache=5d
url_regex=.* suffix=css  ttl-in-cache=5d
url_regex=.* suffix=html  ttl-in-cache=5d

END
}

function config_cache_storage
{
	valid_integer=0
	while [ ${valid_integer} != 1 ]
	do
		ram_cache_size=
		echo 
		echo "Please specify RAM cache size."
		echo "The unit is MB.  Please type an integer only."
		echo "The recommended value is 200 per GB of RAM on your server."
		echo 
		read ram_cache_size
		re='^[0-9]+$'
		if ! [[ ${ram_cache_size} =~ $re ]] ; then
			echo "Please type an integer only.";
		else
			valid_integer=1
		fi
	done
	if [ $ram_cache_size -lt 50 ] ; then
                ram_cache_size=50
        fi
	echo 
	echo "RAM cache size set to ${ram_cache_size}M."
	echo 
	echo "CONFIG proxy.config.cache.ram_cache.size INT ${ram_cache_size}M" >> /etc/trafficserver/records.config

	valid_integer=0
	while [ ${valid_integer} != 1 ]
	do
		disk_cache_size=
		echo 
		echo "Please specify disk cache size."
		echo "The unit is MB.  Please type an integer only."
		echo "The recommended value is at least 2048."
		echo 
		read disk_cache_size
		if ! [[ ${disk_cache_size} =~ $re ]] ; then
			echo "please tyope an integer only.";
		else
			valid_integer=1
		fi
	done
	if [ $disk_cache_size -gt 256 ] ; then
		echo 
		echo "Disk cache size set to ${disk_cache_size}M."
		echo 
		echo "var/trafficserver ${disk_cache_size}M" > /etc/trafficserver/storage.config
	else
		echo 
		echo "Disk cache size set to 256M."
		echo 
	fi
}

function config_cache_partitioning
{
	echo 
	echo "Performing disk cache partitioning..."
	for i in 1 2 3 4
	do
		echo "volume=${i} scheme=http size=25%" >> /etc/trafficserver/volume.config
	done
	echo "hostname=* volume=1,2,3,4" > /etc/trafficserver/hosting.config
	echo "Disk cache partitioned."
	echo 
}

function config_cache_dynamic_content
{
	echo
	echo "CONFIG proxy.config.http.cache.cache_urls_that_look_dynamic INT 1" >> /etc/trafficserver/records.config
	echo "Cache rules updated!"
	echo "Traffic Server will cache dynamic content."
	echo 
}

function config_mapping_reverse_proxy
{
	proxy_hostname=$1
	origin_hostname=$2
	origin_scheme=$3
	echo 
	echo "Adding mapping rules for ${proxy_hostname} as a reverse proxy of ${origin_hostname}..."
	echo "redirect http://${proxy_hostname}/ https://${proxy_hostname}/" >> /etc/trafficserver/remap.config
	echo "map https://${proxy_hostname}/ ${origin_scheme}://${origin_hostname}/" >> /etc/trafficserver/remap.config
	echo "reverse_map ${origin_scheme}://${origin_hostname}/ https://${proxy_hostname}/" >> /etc/trafficserver/remap.config
	echo "3 rules added."
	echo 
}

function config_mapping_cdn
{
	cdn_hostname=$1
	origin_ip=$2
	origin_scheme=$3
	origin_port=$4
	echo 
	echo "Adding mapping rules for ${cdn_hostname}..."
	if [ "$origin_scheme" = "https" ] ; then
		echo "redirect http://${cdn_hostname}/ https://${cdn_hostname}/" >> /etc/trafficserver/remap.config
	fi
	echo "map https://${cdn_hostname}/ ${origin_scheme}://${origin_ip}:${origin_port}/" >> /etc/trafficserver/remap.config
	echo "2 rules added."
	echo 
}

function add_reverse_proxy
{
	echo 
	echo "Please specify your proxy domain name (e.g., proxy.example.com):"
	read proxy_hostname_add
	echo "Please specify the origin website domain name (e.g., origin.example.com):"
	read origin_hostname_add
	echo "Please specify the origin website IP address (e.g., 88.88.88.88).  If it has multiple IPs, any would work:"
	read origin_ip_add
	echo "Is the origin website using HTTPS or HTTP?  Type 1 for HTTPS, or 2 for HTTP.  If both works, then either is fine:"
	read isHTTPS
	if [ $isHTTPS = 1 ] ; then
		config_mapping_reverse_proxy $proxy_hostname_add $origin_hostname_add https
	else
		config_mapping_reverse_proxy $proxy_hostname_add $origin_hostname_add http
	fi
	echo "${proxy_hostname_add}		RevProxy		${origin_hostname_add}" >> /etc/trafficserver/hostsavailable.sun
	echo "Would you like to configure SSL certificates for domain name ${proxy_hostname_add} now?"
	echo "We can set up SSL with your own certificates, or can issue a free Let's Encrypt SSL certificate for you, if you have already pointed your domain to this server."
	echo "How would you like to proceed?"
	echo "1: I know the absolute path to my certificate files (private key, certificate, CA chain (optional))."
	echo "2: I have pointed my domain name to this server, and I want a free Let's Encrypt certificate."
	echo "3: I forgot the path to my certificate files, so I need to go back to SSH and find them; or I do not need SSL certificate for this domain."
	echo "Please select 1, 2, or 3:"
	read choice_ssl
	case $choice_ssl in 
		1 ) 	config_ssl_non_le $proxy_hostname_add $origin_ip_add
				;;
		2 ) 	config_ssl_le $proxy_hostname_add $origin_ip_add
				;;
		3 ) 	config_ssl_later
				;;
		* )		echo "Error!" 
				exit 1
				;;
	esac
}

function add_cdn
{
	echo 
	echo "Please specify your website domain name (e.g., example.com):"
	read cdn_hostname_add
	echo "Please specify the origin website IP address (e.g., 88.88.88.88).  If it has multiple IPs, any would work:"
	read origin_ip_add
	echo "Is the origin website using HTTPS or HTTP?  Type 1 for HTTPS, or 2 for HTTP.  If both works, then either is fine:"
	read isHTTPS
	if [ $isHTTPS = 1 ] ; then
		cdn_port=443
		config_mapping_cdn $cdn_hostname_add $origin_ip_add https 443
	else
		cdn_port=80
		config_mapping_cdn $cdn_hostname_add $origin_ip_add http 80
	fi
	echo "${cdn_hostname_add}		CDN		${origin_ip_add}:${cdn_port}" >> /etc/trafficserver/hostsavailable.sun
	echo "Would you like to configure SSL certificates for domain name ${cdn_hostname_add} now?"
	echo "We can set up SSL with your own certificates, or can issue a free Let's Encrypt SSL certificate for you, if you have already pointed your domain to this server."
	echo "How would you like to proceed?"
	echo "1: I know the absolute path to my certificate files (private key, certificate, CA chain (optional))."
	echo "2: I have pointed my domain name to this server, and I want a free Let's Encrypt certificate."
	echo "3: I forgot the path to my certificate files, so I need to go back to SSH and find them; or I do not need SSL certificate for this domain."
	echo "Please select 1, 2, or 3:"
	read choice_ssl
	case $choice_ssl in 
		1 ) 	config_ssl_non_le $cdn_hostname_add $origin_ip_add
				;;
		2 ) 	config_ssl_le $cdn_hostname_add $origin_ip_add
				;;
		3 ) 	config_ssl_later
				;;
		* )		echo "Error!" 
				exit 1
				;;
	esac
}

function config_ssl_selection
{
	# this function is only called from menu option 4.
	echo "We can set up SSL with your own certificates, or can issue a free Let's Encrypt SSL certificate for you, if you have already pointed your domain to this server."
	echo "How would you like to proceed?"
	echo "1: I know the absolute path to my certificate files (private key, certificate, CA chain (optional))."
	echo "2: I have pointed my domain name to this server, and I want a free Let's Encrypt certificate."
	echo "3: I forgot the path to my certificate files, so I need to go back to SSH and find them; or I do not need SSL certificate for this domain."
	echo "Please select 1, 2, or 3:"
	read choice_ssl
	if [ $choice_ssl = 3 ] ; then
		config_ssl_later
	else
		echo 
		echo "Please specify your domain name (e.g., qing.su): "
		read ssl_hostname_add
		echo "Please specify the origin server IP address (e.g., 88.88.88.88): "
		read ssl_ip_add
		case $choice_ssl in 
			1 ) 	config_ssl_non_le $ssl_hostname_add $ssl_ip_add
					;;
			2 ) 	config_ssl_le $ssl_hostname_add $ssl_ip_add
					;;
			3 ) 	config_ssl_later
					;;
			* )		echo "Error!" 
					exit 1
					;;
		esac
	fi
}

function config_ssl_later
{
	echo 
	echo "No problem!  Please take your time and find your certificates."
	echo "You can always run this script again and set up SSL certificates for your instances later."
	echo "Simply choose Option 4 in the main menu."
	trafficserver restart
	echo "Thank you for using this script!  Have a nice day!"
	exit 0
}
	
function display_license
{
	echo 
	echo '*******************************************************************'
	echo '*       One-click CDN installation script                         *'
	echo '*       Version 0.0.3                                             *'
	echo '*       Author: shc (Har-Kuun) https://qing.su                    *'
	echo '*       https://github.com/Har-Kuun/oneclickCDN                   *'
	echo '*       Thank you for using this script.  E-mail: hi@qing.su      *'
	echo '*******************************************************************'
}

function config_ssl_non_le
{
	echo 
	echo "Please specify your private key file location (e.g., /etc/certs/qing.su.key): "
	read priv_key_file
	echo "Please specify your certificate file location (e.g., /etc/certs/qing.su.crt): "
	read cert_file
	echo "Is your certificate chained? (i.e., are CA-certficates already included in your certificate file?) [Y/N]:"
	read is_chained
	if [ "x${is_chained}" != "xY" ]
	then
		echo "Please specify your CA-certificates file location (e.g., /etc/certs/qing.su.ca-bundle): "
		read ca_cert_file
	fi
	# $1 is hostname and $2 is IP
	cp $priv_key_file /etc/trafficserver/ssl/$1.key
	cp $cert_file /etc/trafficserver/ssl/$1.crt
	echo "Configuring SSL certificates for $2..."
	if [ "x${is_chained}" = "xY" ]
	then
		echo "dest_ip=$2 ssl_cert_name=$1.crt ssl_key_name=$1.key" >> /etc/trafficserver/ssl_multicert.config
	else
		cp $ca_cert_file /etc/trafficserver/ssl/$1.ca.crt
		echo "dest_ip=$2 ssl_cert_name=$1.crt ssl_key_name=$1.key ssl_ca_name=$1.ca.crt" >> /etc/trafficserver/ssl_multicert.config
	fi
	echo "SSL certificates successfully configured."
	echo "Origin IP: $2"
	echo "Private key file: /etc/trafficserver/ssl/$1.key"
	echo "Certificate file: /etc/trafficserver/ssl/$1.crt"
	if [ "x${is_chained}" != "xY" ] ; then
		echo "Intermediate certificate: /etc/trafficserver/ssl/$1.ca.crt"
	fi
	chown -R nobody /etc/trafficserver/ssl/
	chmod -R 0760 /etc/trafficserver/ssl/
	echo 
}

function config_ssl_le
{
	origin_ip=$2
	hostname_le=$1
	echo 
	echo "Starting to issue free certificate from Let's Encrypt..."
	echo "Please keep in mind that this feature is experimental..."
	echo 
	echo "Stopping trafficserver..."
	echo "Please input your e-mail address: "
	read email_le
	trafficserver stop 
	certbot certonly --standalone --agree-tos --email $email_le -d $hostname_le
	cp /etc/letsencrypt/live/${hostname_le}/fullchain.pem /etc/trafficserver/ssl/${hostname_le}.crt
	cp /etc/letsencrypt/live/${hostname_le}/privkey.pem /etc/trafficserver/ssl/${hostname_le}.key
	echo "dest_ip=${origin_ip} ssl_cert_name=${hostname_le}.crt ssl_key_name=${hostname_le}.key" >> /etc/trafficserver/ssl_multicert.config
	chown -R nobody /etc/trafficserver/ssl/
	chmod -R 0760 /etc/trafficserver/ssl/
	trafficserver start
	echo 
}

function display_config_locations
{
	echo 
	echo "General configurations: /etc/trafficserver/records.config"
	echo "SSL: /etc/trafficserver/ssl_multicert.config"
	echo "Mapping rules: /etc/trafficserver/remap.config"
	echo "Cache rules: /etc/trafficserver/cache.config"
	echo "Disk cache size: /etc/trafficserver/storage.config"
	echo 
	echo "Log files location: /usr/local/var/log/trafficserver"
	echo 
	echo "For other configurations, check the official wiki:"
	echo "https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html#configuration-variables"
	echo 
	echo "Do not forget to restart Traffic Server after modifying config files."
	echo "Simply run: \"trafficserver restart\""
	echo "Thank you.  Press return key to continue."
	read cache_all_variable
	echo 
}

function view_stats
{
	cat /etc/trafficserver/hostsavailable.sun
	echo 
	echo "Please specify the website that you would like to check stats."
	echo "Note: type in the Origin IP:Port of the origin website."
	echo "For example, 88.88.88.88:443."
	echo "Please specify:"
	read view_stats_host
	traffic_logstats -o $view_stats_host
	echo 
}

function display_useful_commands
{
	echo 
	echo "View Traffic Server stats: traffic_top"
	echo "Start/stop/restart Traffic Server: trafficserver start/stop/restart"
	echo "Check whether Traffic Server is running: trafficserver status"
	echo "Decode via header: traffic_via '[xXxXxX]'"
	echo "Reload Traffic Server config files: traffic_ctl config reload"
	echo 
	echo "You can always run this script again to add a CDN website, configure SSL certificates, check stats, etc."
	echo 
	echo "Press return key to continue."
	read cache_all_variable
}

function enable_header_rewriter
{
	echo
	echo "Setting up header rewriter..."
	echo "header_rewrite.so /etc/trafficserver/header_rewrite.config" > /etc/trafficserver/plugin.config
	touch /etc/trafficserver/header_rewrite.config
	echo "Header rewriter plugin enabled!"
	echo 
}

function enable_CORS
{
	echo
	echo "Setting up cross-origin resource sharing headers..."
	echo "rm-header Access-Control-Allow-Origin *" >> /etc/trafficserver/header_rewrite.config
	echo "add-header Access-Control-Allow-Origin *" >> /etc/trafficserver/header_rewrite.config
	echo "CORS header added!"
	echo 
}

function customize_server_header
{
	echo 
	echo "How would you like your server to be called?"
	read cdn_server_header
	echo "OK.  Setting server header now..."
	echo "cond %\{SEND_RESPONSE_HDR_HOOK\} [AND]" >> /etc/trafficserver/header_rewrite.config
	echo "cond %{HEADER:server} =ATS/${TS_VERSION}" >> /etc/trafficserver/header_rewrite.config
	echo "set-header server \"${cdn_server_header}\"" >> /etc/trafficserver/header_rewrite.config
	echo "Server header set!"
	echo 
}

function clear_all_cache
{
	echo 
	echo "Stopping Traffic Server..."
	trafficserver stop
	echo "Purging all cache..."
	traffic_server -Cclear
	echo "Cache purged successfully."
	echo "Starting Traffic Server..."
	trafficserver start
	echo 
}

function change_cdn_ip
{
	echo
	echo "Please tell me your old Origin server IP.  No domain name required."
	read old_ip
	echo "OK.  Then tell me your new Origin server IP.  No domain name required."
	read new_ip
	sed 's/${old_ip}/${new_ip}/g' /etc/trafficserver/hostsavailable.sun
	sed 's/${old_ip}/${new_ip}/g' /etc/trafficserver/ssl_multicert.config
	sed 's/${old_ip}/${new_ip}/g' /etc/trafficserver/remap.config
	echo "IP changed from ${old_ip} to ${new_ip}"
	echo 
}

function reconfigure_traffic_server
{
	echo 
	echo "Are you sure to reconfigure Traffic Server?"
	echo "All previous configurations will be cleared."
	echo "Mapping rules and SSL certificate settings will be kept."
	echo "Would you like to continue? [Y/N]"
	read do_reconfigure_ts
	if [ "x$do_reconfigure_ts" = "xY" ] ; then
		echo 
		echo "Configuring Traffic Server..."
		config_main_records
		echo 
		echo "Would you like to configure cache rules automatically? [Y/N]"
		read do_config_cache_rules
		if [ "x$do_config_cache_rules" = "xY" ] || [ "x$do_config_cache_rules" = "xy" ] ; then
			echo "Configuring cache rules..."
			config_cache_rules
			echo "Cache rules configured successfully."
		else
			echo "You can configure cache rules manually at /etc/trafficserver/cache.config.  Make sure to run \"trafficserver restart\" after changing the cache rules."
		fi
		echo 
		echo "Configuring cache size..."
		config_cache_storage
		rm -f /etc/trafficserver/volume.config
		config_cache_partitioning
		rm -f /etc/trafficserver/header_rewrite.config
		enable_header_rewriter
		echo "Would you like Traffic Server to cache dynamic content? [Y/N]"
		read do_cache_dynamic_content
		if [ "x$do_cache_dynamic_content" = "xY" ] || [ "x$do_cache_dynamic_content" = "xy" ] ; then
			echo "Updating cache rules..."
			config_cache_dynamic_content
		else
			echo "Traffic Server will not cache dynamic content!"
			echo 
		fi
		echo "Would you like to enable \"Allow-Control-Allow-Origin\" header (CORS)?"
		echo "Please choose Y if you have no idea what it is. [Y/N]"
		read do_enable_CORS
		if [ "x$do_enable_CORS" = "xY" ] || [ "x$do_enable_CORS" = "xy" ] ; then
			enable_CORS
		else
			echo "CORS not configured."
			echo 
		fi
		echo "The \"server\" header can be a short phrase, like \"shc-cdn-server 1.0.0\", or \"Traffic Server 8.0.8\"."
		echo "If you do not change it, the default value is \"ATS/${TS_VERSION}\""
		echo "Would you like to change it? [Y/N]"
		read do_change_server_header
		if [ "x$do_change_server_header" = "xY" ] || [ "x$do_change_server_header" = "xy" ] ; then
			customize_server_header
		else
			echo "Server header tag value not changed."
			echo 
		fi
		echo "Configuration successfully finished!"
		echo 
	else
		echo 
		echo "Traffic Server not reconfigured."
		echo 
	fi
}

function renew_le_certificate
{
	echo 
	echo "What is the domain name that you wish to renew Let's Encrypt certificate?"
	read renew_le_domain
	echo "OK.  Stopping Traffic Server..."
	trafficserver stop 
	echo 
	echo "Renewing SSL certificate for ${renew_le_domain}..."
	echo 
	certbot certonly --standalone --agree-tos -d $renew_le_domain
	cp -f /etc/letsencrypt/live/${renew_le_domain}/fullchain.pem /etc/trafficserver/ssl/${renew_le_domain}.crt
	cp -f /etc/letsencrypt/live/${renew_le_domain}/privkey.pem /etc/trafficserver/ssl/${renew_le_domain}.key
	chown -R nobody /etc/trafficserver/ssl/
	chmod -R 0760 /etc/trafficserver/ssl/
	echo "SSL certificate for ${renew_le_domain} successfully renewed."
	echo 
	echo "Starting Traffic Server..."
	trafficserver start
	echo 
}

function say_goodbye
{
	echo 
	echo "Restarting Traffic Server now..."
	trafficserver restart
	echo 
	echo "Thank you for using this script written by https://qing.su"
	echo "You can always run this script again to add a CDN website, configure SSL certificates, list current websites, check stats, etc."
	echo 
	echo "Bye!  Have a nice day."
	echo 
	key=0
}

function run_on_startup
{
	cat > /etc/systemd/system/trafficserver.service <<END

[Unit]
Description=Apache Traffic Server
After=network.service systemd-networkd.service network-online.target dnsmasq.service

[Service]
Type=simple
ExecStart=/usr/local/bin/traffic_manager
ExecReload=/usr/local/bin/traffic_ctl config reload
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target

END
	
	chmod 644 /etc/systemd/system/trafficserver.service
	systemctl daemon-reload
	systemctl enable trafficserver.service
}

function main
{
	current_dir=$(pwd)
	display_license
	OS=UNSUPPORTED
	if [ "x$OS_CHECK_ENABLED" != "xOFF" ] ; then
		check_OS
	fi
	echo 
	echo "Your OS is $OS"
	echo 
	echo "Checking Traffic Server installation..."
	check_TS
	if [ $TS_INSTALLED = 0 ] ; then
		echo 
		echo "Traffic Server not installed.  Would you like to install it now?"
		echo "Depending on your server specs, you may or may not need to add some SWAP before you proceed."
		echo "This script needs 1500 MB of RAM for the first time to build from source.  It runs perfectly on a 512 MB VPS once it finishes the installation."
		echo "If you think you don't have enough RAM now, please quit, add more SWAP, and run this script again."
		echo 
		echo "Please indicate if you would like to install now: (Y/N)"
		read install_or_not
		if [ "x$install_or_not" != "xY" ] && [ "x$install_or_not" != "xy" ] ; then
			echo 
			echo "Aborted!"
			echo 
			exit 0
		fi
		if [ "x$OS" = "xCENTOS7" ] || [ "x$OS" = "xCENTOS8" ] ; then
			install_TS_CentOS
		else
			install_TS
		fi
		echo 
		echo "Configuring Traffic Server..."
		config_main_records
		echo 
		echo "Would you like to configure cache rules automatically? [Y/N]"
		read do_config_cache_rules
		if [ "x$do_config_cache_rules" = "xY" ] || [ "x$do_config_cache_rules" = "xy" ] ; then
			echo "Configuring cache rules..."
			config_cache_rules
			echo "Cache rules configured successfully."
		else
			echo "You can configure cache rules manually at /etc/trafficserver/cache.config.  Make sure to run \"trafficserver restart\" after changing the cache rules."
		fi
		echo 
		echo "Configuring cache size..."
		config_cache_storage
		config_cache_partitioning
		enable_header_rewriter
		echo "Would you like Traffic Server to cache dynamic content? [Y/N]"
		read do_cache_dynamic_content
		if [ "x$do_cache_dynamic_content" = "xY" ] || [ "x$do_cache_dynamic_content" = "xy" ] ; then
			echo "Updating cache rules..."
			config_cache_dynamic_content
		else
			echo "Traffic Server will not cache dynamic content!"
			echo 
		fi
		echo "Would you like to enable \"Allow-Control-Allow-Origin\" header (CORS)?"
		echo "Please choose Y if you have no idea what it is. [Y/N]"
		read do_enable_CORS
		if [ "x$do_enable_CORS" = "xY" ] || [ "x$do_enable_CORS" = "xy" ] ; then
			enable_CORS
		else
			echo "CORS not configured."
			echo 
		fi
		echo "The \"server\" header can be a short phrase, like \"shc-cdn-server 1.0.0\", or \"Traffic Server 8.0.8\"."
		echo "If you do not change it, the default value is \"ATS/${TS_VERSION}\""
		echo "Would you like to change it? [Y/N]"
		read do_change_server_header
		if [ "x$do_change_server_header" = "xY" ] || [ "x$do_change_server_header" = "xy" ] ; then
			customize_server_header
		else
			echo "Server header tag value not changed."
			echo 
		fi
		echo "Configuration successfully finished!"
		echo "Please proceed to the next step and add your first CDN website."
		echo 
	else
		echo 
		echo "Traffic Server installed and running!"
		echo 
	fi
	key=1
	while [ $key != 0 ] ; do
		echo 
		echo "How can I help you today?"
		echo "1 - List all current CDN websites."
		echo "2 - Purge all cache."
		echo "3 - Add a CDN website."
		echo "4 - Configure SSL for a website."
		echo "5 - Locate configuration and log files."
		echo "6 - View stats of a website."
		echo "7 - List useful commands."
		echo "8 - Display author information."
		echo "11 - Change IP address of a website."
		echo "12 - Reconfigure Traffic Server."
		echo "13 - Renew Let's Encrypt certificates."
	#	if [ "x$REVERSE_PROXY_MODE_ENABLED" = "xON" ] ; then
	#		echo "73 - Add a reverse proxy website (Experimental only)."
	#	fi
		echo "0 - Save all changes and quit this script."
		echo "Please select 1/2/3/4/5/6/7/8/11/12/13/0: "
		read key
		case $key in 
			1 ) 		echo 
					cat /etc/trafficserver/hostsavailable.sun
						;;
			2 ) 		clear_all_cache
						;;
			3 )		add_cdn
						;;
			4 ) 		config_ssl_selection
						;;
			5 ) 		display_config_locations
						;;
			6 ) 		view_stats
						;;
			7 ) 		display_useful_commands
						;;
			8 ) 		display_license
						;;
			73 )		if [ "x$REVERSE_PROXY_MODE_ENABLED" = "xON" ] ; then
						add_reverse_proxy
					fi
						;;
			11 )		change_cdn_ip
						;;
			12 )		reconfigure_traffic_server
						;;
			13 )		renew_le_certificate
						;;
			0 ) 		say_goodbye
						;;
		esac
	done
	exit 0
}

###############################################################
#                                                             #
#               The main function starts here.                #
#                                                             #
###############################################################

main
