#!/bin/bash
#################################################################
#    One-click CDN Installation Script v0.0.5                   #
#    Written by shc (https://qing.su)                           #
#    Github link: https://github.com/Har-Kuun/OneClickCDN       #
#    Contact me: https://t.me/hsun94   E-mail: hi@qing.su       #
#                                                               #
#    This script is distributed in the hope that it will be     #
#    useful, but ABSOLUTELY WITHOUT ANY WARRANTY.               #
#                                                               #
#    Thank you for using this script.                           #
#################################################################


#您可以在这里修改Traffic Server源码下载链接。
#查看https://www.apache.org/dyn/closer.cgi/trafficserver获取最新版本链接。

TS_DOWNLOAD_LINK="https://mirrors.ocf.berkeley.edu/apache/trafficserver/trafficserver-8.0.8.tar.bz2"
TS_VERSION="8.0.8"



#您可以开启实验性的功能： 反代其他网站。
#该功能目前仍有问题，您可能需要手动调试。
#如果您希望启用该功能，可以将下面变量的值设为ON, 然后在主菜单中输入特殊值, 添加反代实例。

REVERSE_PROXY_MODE_ENABLED=OFF



#默认条件下，此脚本仅支持Ubuntu 20, Debian 10, 以及CentOS 7/8.
#您可以在下面关闭OS检查开关，然后自行修改代码以在其它系统上安装。
#请注意，如果您试图在其他系统上安装，将可能导致不可预知的错误。请注意备份。

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
			echo "在Ubuntu 18系统上使用本脚本可能会遇到TLS握手错误。"
			echo "Please consider upgrading to Ubuntu 20 (simply run \"do-release-upgrade -d\")."
			echo "如果您仍希望在Ubuntu 18上安装，请修改OS_CHECK_ENABLED开关的值。"
			echo 
			exit 1
		else
			cat /etc/lsb-release | grep "DISTRIB_RELEASE=20." >/dev/null
			if [ $? = 0 ]
			then
				OS=UBUNTU20
			else
				say "很抱歉，改脚本仅支持Ubuntu 20, Debian 10与CentOS 7/8." red
				echo 
				exit 1
			fi
		fi
	elif [ -f /etc/debian_version ] ; then
		cat /etc/debian_version | grep "^10." >/dev/null
		if [ $? = 0 ] ; then
			OS=DEBIAN10
			echo "本脚本仅实验性地支持Debian 10, 如有bug欢迎汇报。"
			echo 
		else
			cat /etc/debian_version | grep "^9." >/dev/null
			if [ $? = 0 ] ; then
				OS=DEBIAN9
				echo "本脚本仅实验性地支持Debian 9. 您可能会遇到TLS握手错误。"
				echo "如果您仍希望在Debian 9上安装，请修改OS_CHECK_ENABLED开关的值。"
				echo 
				exit 1
			else
				say "很抱歉，改脚本仅支持Ubuntu 20, Debian 10与CentOS 7/8." red
				echo 
				exit 1
			fi
		fi
	elif [ -f /etc/redhat-release ] ; then
		cat /etc/redhat-release | grep " 8." >/dev/null
		if [ $? = 0 ] ; then
			OS=CENTOS8
			echo "本脚本仅实验性地支持CentOS 8, 如有bug欢迎汇报。"
			echo "如果您无法访问您的网站，请尝试禁用selinux或firewalld."
			echo 
		else
			cat /etc/redhat-release | grep " 7." >/dev/null
			if [ $? = 0 ] ; then
				OS=CENTOS7
				echo "本脚本仅实验性地支持CentOS 7, 如有bug欢迎汇报。"
				echo "如果您无法访问您的网站，请尝试禁用selinux或firewalld."
				echo 
			else
				echo "很抱歉，此脚本仅支持Ubuntu 20, Debian 10, CentOS 7/8."
				echo
				exit 1
			fi
		fi
	else
		echo "很抱歉，此脚本仅支持Ubuntu 20, Debian 10, CentOS 7/8."
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
	say @B"开始Traffic Server安装..." green
	echo "..."
	echo "..."
	echo "移除Nginx与Apache..."
	apt-get remove nginx apache -y
	echo "安装依赖环境..."
	apt-get update && apt-get upgrade -y
	apt-get install wget curl tar certbot automake libtool pkg-config libmodule-install-perl gcc g++ libssl-dev tcl-dev libpcre3-dev libcap-dev libhwloc-dev libncurses5-dev libcurl4-openssl-dev flex autotools-dev bison debhelper dh-apparmor gettext intltool-debian libbison-dev libexpat1-dev libfl-dev libsigsegv2 libsqlite3-dev m4 po-debconf tcl8.6-dev zlib1g-dev -y
	wget $TS_DOWNLOAD_LINK
	tar xjf trafficserver-${TS_VERSION}.tar.bz2
	rm -f trafficserver-${TS_VERSION}.tar.bz2
	cd ${current_dir}/trafficserver-${TS_VERSION}
	echo "开始从源文件编译Traffic Server..."
	./configure --enable-experimental-plugins
	if [ -f ${current_dir}/trafficserver-${TS_VERSION}/config.status ] ; then
		say @B"依赖环境满足条件！" green
		say @B"开始编译..." green
		echo
	else
		echo 
		say "依赖环境缺失。" red
		echo "请核查日志，安装缺失的依赖环境，然后再次运行此脚本。"
		echo "您也可以在这里https://github.com/Har-Kuun/OneClickCDN/issues报告此问题并贴出您的报错日志，以便我改进此脚本。"
		echo "感谢！"
		echo 
		exit 1
	fi
	make
	make install
	if [ -f /usr/local/bin/traffic_manager ] ; then
		echo 
		say @B"Traffic Server 安装成功！" green
		echo
	else
		echo
		say "Traffic Server 安装失败。" red
		echo "请检查上面的日志报错信息。"
		echo "您也可以在这里https://github.com/Har-Kuun/OneClickCDN/issues报告此问题并贴出您的报错日志，以便我改进此脚本。"
		echo "感谢！"
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
	say @B"Traffic Server 启动成功！" green
	echo "Domain		Type(CDN/RevProxy)		OriginIP" > /etc/trafficserver/hostsavailable.sun
#	echo "trafficserver start" >> /etc/rc.local
	run_on_startup
	echo 
}

function install_TS_CentOS
{
	say @B"开始Traffic Server安装..." green
	echo "..."
	echo "..."
	echo "移除Nginx与Apache..."
	yum remove httpd nginx -y
	echo "安装依赖环境..."
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
	echo "开始从源文件编译Traffic Server..."
	./configure --enable-experimental-plugins
	if [ -f ${current_dir}/trafficserver-${TS_VERSION}/config.status ] ; then
		say @B"依赖环境满足条件！" green
		say @B"开始编译..." green
		echo
	else
		echo 
		say "依赖环境缺失。" red
		echo "请核查日志，安装缺失的依赖环境，然后再次运行此脚本。"
		echo "您也可以在这里https://github.com/Har-Kuun/OneClickCDN/issues报告此问题并贴出您的报错日志，以便我改进此脚本。"
		echo "感谢！"
		echo 
		exit 1
	fi
	make
	make install
	if [ -f /usr/local/bin/traffic_manager ] ; then
		echo 
		say @B"Traffic Server 安装成功！" green
		echo
	else
		echo
		say "Traffic Server 安装失败。" red
		echo "请检查上面的日志报错信息。"
		echo "您也可以在这里https://github.com/Har-Kuun/OneClickCDN/issues报告此问题并贴出您的报错日志，以便我改进此脚本。"
		echo "感谢！"
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
	say @B"Traffic Server 启动成功！" green
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
CONFIG proxy.config.http.push_method_enabled INT 1
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
		echo "请输入内存缓存大小。"
		echo "单位为M. 请输入一个整数值。"
		echo "推荐值为200M每GB内存。"
		echo 
		read ram_cache_size
		re='^[0-9]+$'
		if ! [[ ${ram_cache_size} =~ $re ]] ; then
			say @B"请仅输入一个证书。" yellow
		else
			valid_integer=1
		fi
	done
	if [ $ram_cache_size -lt 50 ] ; then
                ram_cache_size=50
        fi
	echo 
	say @B"RAM缓存值已设置为 ${ram_cache_size}M." green
	echo 
	echo "CONFIG proxy.config.cache.ram_cache.size INT ${ram_cache_size}M" >> /etc/trafficserver/records.config

	valid_integer=0
	while [ ${valid_integer} != 1 ]
	do
		disk_cache_size=
		echo 
		echo "请输入磁盘缓存大小。"
		echo "单位为M. 请输入一个整数值。"
		echo "推荐值为至少2048M."
		echo 
		read disk_cache_size
		if ! [[ ${disk_cache_size} =~ $re ]] ; then
			say @B"please type an integer only." yellow
		else
			valid_integer=1
		fi
	done
	if [ $disk_cache_size -gt 256 ] ; then
		echo 
		say @B"磁盘缓存已设置为 ${disk_cache_size}M." green
		echo 
		echo "var/trafficserver ${disk_cache_size}M" > /etc/trafficserver/storage.config
	else
		echo 
		say @B"磁盘缓存已设置为 256M." green
		echo 
	fi
}

function config_cache_partitioning
{
	echo 
	echo "正在为磁盘缓存分区..."
	for i in 1 2 3 4
	do
		echo "volume=${i} scheme=http size=25%" >> /etc/trafficserver/volume.config
	done
	echo "hostname=* volume=1,2,3,4" > /etc/trafficserver/hosting.config
	say @B"磁盘缓存分区成功。" green
	echo 
}

function config_cache_dynamic_content
{
	echo
	echo "CONFIG proxy.config.http.cache.cache_urls_that_look_dynamic INT 1" >> /etc/trafficserver/records.config
	say @B"已更新缓存规则!" green
	say @B"Traffic Server将缓存动态内容。" green
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
	say @B"3 rules added." green
	echo 
}

function config_mapping_cdn
{
	cdn_hostname=$1
	origin_ip=$2
	origin_scheme=$3
	origin_port=$4
	echo 
	echo "为${cdn_hostname}添加映射规则..."
	if [ "$origin_scheme" = "https" ] ; then
		echo "redirect http://${cdn_hostname}/ https://${cdn_hostname}/" >> /etc/trafficserver/remap.config
	fi
	echo "map https://${cdn_hostname}/ ${origin_scheme}://${origin_ip}:${origin_port}/" >> /etc/trafficserver/remap.config
	say @B"已添加2条规则。" green
	echo 
}

function add_reverse_proxy
{
	echo 
	echo "请输入 your proxy domain name (e.g., proxy.example.com):"
	read proxy_hostname_add
	echo "请输入源站域名(比如origin.example.com):"
	read origin_hostname_add
	echo "请输入源站IP地址。如果源站有多个IP地址，可以填任意一个。"
	read origin_ip_add
	echo "源站是否启用SSL？如果是HTTPS, 请输入1; 如果是HTTP, 请输入2."
	read isHTTPS
	if [ $isHTTPS = 1 ] ; then
		config_mapping_reverse_proxy $proxy_hostname_add $origin_hostname_add https
	else
		config_mapping_reverse_proxy $proxy_hostname_add $origin_hostname_add http
	fi
	echo "${proxy_hostname_add}		RevProxy		${origin_hostname_add}" >> /etc/trafficserver/hostsavailable.sun
	echo "请问您是否想现在为域名${proxy_hostname_add}配置SSL证书？"
	echo "您可以提供您自己的证书；如果您已经将域名指向了该服务器的IP地址，您也可以一键生成免费的Let's Encrypt SSL证书。"
	echo "请输入您的选项。"
	echo "1: 我知道我的证书文件的路径（私钥，证书，CA中间链证书（可选）），我想提供我自己的证书。"
	echo "2: 我已经将我的域名指向了该服务器的IP, 我想生成免费的Let's Encrypt证书。"
	echo "3: 我不记得证书文件放在哪儿了，得去找找；或者我暂时不想为该域名设置SSL."
	echo "请选择 1, 2, or 3:"
	read choice_ssl
	case $choice_ssl in 
		1 ) 	config_ssl_non_le $proxy_hostname_add $origin_ip_add
				;;
		2 ) 	config_ssl_le $proxy_hostname_add $origin_ip_add
				;;
		3 ) 	config_ssl_later
				;;
		* )		echo "错误!" 
				exit 1
				;;
	esac
}

function add_cdn
{
	echo 
	echo "请输入您网站的域名（比如example.com）："
	read cdn_hostname_add
	echo "请输入源站IP地址。如果源站有多个IP地址，可以填任意一个。"
	read origin_ip_add
	echo "源站是否启用SSL？如果是HTTPS, 请输入1; 如果是HTTP, 请输入2."
	read isHTTPS
	if [ $isHTTPS = 1 ] ; then
		cdn_port=443
		config_mapping_cdn $cdn_hostname_add $origin_ip_add https 443
	else
		cdn_port=80
		config_mapping_cdn $cdn_hostname_add $origin_ip_add http 80
	fi
	echo 
	echo "${cdn_hostname_add}		CDN		${origin_ip_add}:${cdn_port}" >> /etc/trafficserver/hostsavailable.sun
	echo "您是否想要现在为${cdn_hostname_add}配置SSL证书？"
	echo 
	echo "您可以提供您自己的证书；如果您已经将域名指向了该服务器的IP地址，您也可以一键生成免费的Let's Encrypt SSL证书。"
	echo "请输入您的选项。"
	echo 
	echo "1: 我知道我的证书文件的路径（私钥，证书，CA中间链证书（可选）），我想提供我自己的证书。"
	echo "2: 我已经将我的域名指向了该服务器的IP, 我想生成免费的Let's Encrypt证书。"
	echo "3: 我不记得证书文件放在哪儿了，得去找找；或者我暂时不想为该域名设置SSL."
	echo "请选择 1, 2, or 3:"
	read choice_ssl
	case $choice_ssl in 
		1 ) 	config_ssl_non_le $cdn_hostname_add $origin_ip_add
				;;
		2 ) 	config_ssl_le $cdn_hostname_add $origin_ip_add
				;;
		3 ) 	config_ssl_later
				;;
		* )		say "错误!" red
				exit 1
				;;
	esac
}

function config_ssl_selection
{
	# this function is only called from menu option 4.
	echo "您可以提供您自己的证书；如果您已经将域名指向了该服务器的IP地址，您也可以一键生成免费的Let's Encrypt SSL证书。"
	echo "请输入您的选项。"
	echo 
	echo "1: 我知道我的证书文件的路径（私钥，证书，CA中间链证书（可选）），我想提供我自己的证书。"
	echo "2: 我已经将我的域名指向了该服务器的IP, 我想生成免费的Let's Encrypt证书。"
	echo "3: 我不记得证书文件放在哪儿了，得去找找；或者我暂时不想为该域名设置SSL."
	echo "请选择 1, 2, or 3:"
	read choice_ssl
	if [ $choice_ssl = 3 ] ; then
		config_ssl_later
	else
		echo 
		echo "请输入您的域名（比如qing.su）: "
		read ssl_hostname_add
		echo "请输入源站IP地址： "
		read ssl_ip_add
		case $choice_ssl in 
			1 ) 	config_ssl_non_le $ssl_hostname_add $ssl_ip_add
					;;
			2 ) 	config_ssl_le $ssl_hostname_add $ssl_ip_add
					;;
			3 ) 	config_ssl_later
					;;
			* )		say "错误!" red 
					exit 1
					;;
		esac
	fi
}

function config_ssl_later
{
	echo 
	echo "好的，您可以返回SSH查找您的证书文件地址。"
	echo "您随时可以再次运行此脚本，为您的网站设置SSL证书。"
	echo "只需在菜单中选择选项4即可。"
	trafficserver restart
	echo "感谢您使用此程序，祝您生活愉快!"
	exit 0
}
	
function display_license
{
	echo 
	echo '*******************************************************************'
	echo '*       One-click CDN installation script                         *'
	echo '*       Version 0.0.5                                             *'
	echo '*       Author: shc (Har-Kuun) https://qing.su                    *'
	echo '*       https://github.com/Har-Kuun/OneClickCDN                   *'
	echo '*       Thank you for using this script.  E-mail: hi@qing.su      *'
	echo '*******************************************************************'
}

function config_ssl_non_le
{
	echo 
	echo "请输入您的私钥地址 (e.g., /etc/certs/qing.su.key): "
	read priv_key_file
	echo "请输入您的证书地址 (e.g., /etc/certs/qing.su.crt): "
	read cert_file
	echo "该证书是否为全链（即CA中间链证书是否已包含在该证书中）？ [Y/N]:"
	read is_chained
	if [ "x${is_chained}" != "xY" ]
	then
		echo "请输入您的CA中间链证书地址 (e.g., /etc/certs/qing.su.ca-bundle): "
		read ca_cert_file
	fi
	# $1 is hostname and $2 is IP
	echo "为$2配置SSL证书..."
	cp $priv_key_file /etc/trafficserver/ssl/$1.key
	cp $cert_file /etc/trafficserver/ssl/$1.crt
	if [ -f /etc/trafficserver/ssl/$1.crt ] && [ -f /etc/trafficserver/ssl/$1.key ] ; then
		if [ "x${is_chained}" = "xY" ] ; then
			echo "dest_ip=$2 ssl_cert_name=$1.crt ssl_key_name=$1.key" >> /etc/trafficserver/ssl_multicert.config
		else
			cp $ca_cert_file /etc/trafficserver/ssl/$1.ca.crt
			echo "dest_ip=$2 ssl_cert_name=$1.crt ssl_key_name=$1.key ssl_ca_name=$1.ca.crt" >> /etc/trafficserver/ssl_multicert.config
		fi
		say @B"SSL证书配置成功。" green
		echo "源站IP: $2"
		echo "私钥文件地址: /etc/trafficserver/ssl/$1.key"
		echo "证书文件地址: /etc/trafficserver/ssl/$1.crt"
		if [ "x${is_chained}" != "xY" ] ; then
			echo "CA中间链证书地址: /etc/trafficserver/ssl/$1.ca.crt"
		fi
		echo 
	else
		say "SSL配置失败！" red
		echo "请检查上面的日志。"
		echo 
		exit 1
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
	echo "开始用Let's Encrypt生成免费SSL证书。..."
	echo "该功能仍在实验阶段，请您知悉。..."
	echo 
	echo "关闭Traffic Server..."
	echo "请输入一个邮箱地址: "
	read email_le
	trafficserver stop
	systemctl stop trafficserver
	certbot certonly --standalone --agree-tos --email $email_le -d $hostname_le
	cp /etc/letsencrypt/live/${hostname_le}/fullchain.pem /etc/trafficserver/ssl/${hostname_le}.crt
	cp /etc/letsencrypt/live/${hostname_le}/privkey.pem /etc/trafficserver/ssl/${hostname_le}.key
	if [ -f /etc/trafficserver/ssl/${hostname_le}.key ] ; then
		echo "dest_ip=${origin_ip} ssl_cert_name=${hostname_le}.crt ssl_key_name=${hostname_le}.key" >> /etc/trafficserver/ssl_multicert.config
		say @B"SSL证书配置成功。" green
		echo "源站IP: ${origin_ip}"
		echo "私钥文件地址: /etc/trafficserver/ssl/${hostname_le}.key"
		echo "证书文件地址: /etc/trafficserver/ssl/${hostname_le}.crt"
		echo 
	else
		say "Let's Encrypt SSL配置失败！" red
		echo "请检查上面的日志。"
		echo
		exit 1
	fi
	chown -R nobody /etc/trafficserver/ssl/
	chmod -R 0760 /etc/trafficserver/ssl/
	systemctl start trafficserver
	trafficserver start
	echo 
}

function display_config_locations
{
	echo 
	echo "通用配置: /etc/trafficserver/records.config"
	echo "SSL: /etc/trafficserver/ssl_multicert.config"
	echo "映射规则: /etc/trafficserver/remap.config"
	echo "缓存规则: /etc/trafficserver/cache.config"
	echo "磁盘缓存配额: /etc/trafficserver/storage.config"
	echo 
	echo "日志文件目录: /usr/local/var/log/trafficserver"
	echo 
	echo "其他配置请参考官方文档:"
	echo "https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html#configuration-variables"
	echo 
	echo "如果您修改了配置信息，请重启Traffic Server."
	echo "Simply run: \"trafficserver restart\""
	echo "感谢。请按回车键返回主菜单。"
	read catch_all_variable
	echo 
}

function view_stats
{
	cat /etc/trafficserver/hostsavailable.sun
	echo 
	echo "请指明您想要查看统计数据的网站。"
	echo "请仅输入该网站的源站IP:端口"
	echo "比如88.88.88.88:443"
	echo "请输入:"
	read view_stats_host
	traffic_logstats -o $view_stats_host
	echo 
}

function display_useful_commands
{
	echo 
	echo "查看Traffic Server状态统计: traffic_top"
	echo "启动、停止、重启Traffic Server: trafficserver start/stop/restart"
	echo "查看Traffic Server是否正在运行: trafficserver status"
	echo "via信头信息解密: traffic_via '[xXxXxX]'"
	echo "重新载入Traffic Server配置文件: traffic_ctl config reload"
	echo 
	echo "您可以随时再次运行本程序，添加CDN网站，配置SSL，检查统计数据等。"
	echo 
	echo "请按回车键继续。"
	read catch_all_variable
}

function enable_header_rewriter
{
	echo
	echo "配置header修改器..."
	echo "header_rewrite.so /etc/trafficserver/header_rewrite.config" > /etc/trafficserver/plugin.config
	touch /etc/trafficserver/header_rewrite.config
	say @B"header修改器已启用" green
	echo 
}

function enable_CORS
{
	echo
	echo "设置CORS信头..."
	echo "rm-header Access-Control-Allow-Origin *" >> /etc/trafficserver/header_rewrite.config
	echo "add-header Access-Control-Allow-Origin *" >> /etc/trafficserver/header_rewrite.config
	say @B"CORS信头已添加！" green
	echo 
}

function customize_server_header
{
	echo 
	echo "请给这台服务器取名。"
	read cdn_server_header
	echo "好的，正在设置server信头字段..."
	echo "cond %\{SEND_RESPONSE_HDR_HOOK\} [AND]" >> /etc/trafficserver/header_rewrite.config
	echo "cond %{HEADER:server} =ATS/${TS_VERSION}" >> /etc/trafficserver/header_rewrite.config
	echo "set-header server \"${cdn_server_header}\"" >> /etc/trafficserver/header_rewrite.config
	say @B"Server header set!" green
	echo 
}

function clear_all_cache
{
	echo 
	echo "停止 Traffic Server..."
	trafficserver stop
	echo "正在清除全部缓存..."
	traffic_server -Cclear
	say @B"成功清除全部缓存。" green
	echo "启用 Traffic Server..."
	trafficserver start
	echo 
}

function purge_single_object
{
	echo 
	echo "请输入您想要移出缓存的对象的URL."
	say @B"请包含 \"http://\" or \"https://\"." yellow
	echo 
	read purge_object_url
	read purge_object_domain_name <<< $(echo "$purge_object_url" | awk -F/ '{print $3}')
	read purge_object_domain_name_protocol <<< $(echo "$purge_object_url" | awk -F: '{print $1}')
	echo 
	cat /etc/trafficserver/hostsavailable.sun | grep $purge_object_domain_name >/dev/null
	if [ $? = 0 ] ; then
		if [ "x$purge_object_domain_name_protocol" = "xhttp" ] ; then
			purge_object_result=$(curl -vX PURGE --resolve ${purge_object_domain_name}:80:127.0.0.1 ${purge_object_url} 2>&1 | grep " 200")
		else
			purge_object_result=$(curl -vX PURGE --resolve ${purge_object_domain_name}:443:127.0.0.1 ${purge_object_url} 2>&1 | grep " 200")
		fi
		if [ -n "$purge_object_result" ] ; then
			say @B"对象${purge_object_url}成功移除出缓存。" green
		else
			say "移除${purge_object_url}失败。" red
			say "该对象不存在，或已经移出缓存。" red
		fi
	else
		say "错误!" red
		say "域名${purge_object_domain_name}不存在" red
	fi
	echo "请按回车键返回主菜单。"
	read catch_all_variable
	echo 
}

function purge_list_of_objects
{
	echo 
	echo "您将从缓存中移除一列对象。"
	say @B"请输入储存这些对象URL的列表文件的绝对路径。" yellow
	echo "一条URL一行。请包含 \"http://\" or \"https://\"."
	read purge_object_list_file
	echo 
	if [ -f $purge_object_list_file ] ; then
		purge_object_list_result_file="${purge_object_list_file}_result"
		printf "%-10s   %-12s   %s\n" "Type" "Status" "URL" > $purge_object_list_result_file
		while read line; do 
			if [ "x$line" = "x" ] ; then
				continue
			fi		
			read purge_object_domain_name <<< $(echo "$line" | awk -F/ '{print $3}')
			read purge_object_domain_name_protocol <<< $(echo "$line" | awk -F: '{print $1}')
			cat /etc/trafficserver/hostsavailable.sun | grep $purge_object_domain_name >/dev/null
			if [ $? = 0 ] ; then
				if [ "x$purge_object_domain_name_protocol" = "xhttp" ] ; then
					purge_object_result=$(curl -vX PURGE --resolve ${purge_object_domain_name}:80:127.0.0.1 ${line} 2>&1 | grep " 200")
				else
					purge_object_result=$(curl -vX PURGE --resolve ${purge_object_domain_name}:443:127.0.0.1 ${line} 2>&1 | grep " 200")
				fi
				if [ -n "$purge_object_result" ] ; then
					say @B"PURGE        SUCCESS        ${line}" green
					say @B"PURGE        SUCCESS        ${line}" green >> $purge_object_list_result_file
				else
					say "PURGE        FAILURE        ${line}" red
					say "PURGE        FAILURE        ${line}" red >> $purge_object_list_result_file
				fi
			else
				say "PURGE        WRONG DOMAIN   ${line}" red
				say "PURGE        WRONG DOMAIN   ${line}" red >> $purge_object_list_result_file
			fi
		done < $purge_object_list_file
		say @B"已完成！" green
		say @B"移除缓存结果已储存至${purge_object_list_result_file}。" green
		say @B"您可以使用 \"cat ${purge_object_list_result_file}\" 来读取结果文件。" green
	else
		say "您输入的文件不存在。" red
		say "请核查。" red
	fi
	echo "请按回车键返回主菜单。"
	read catch_all_variable
	echo 
}
	
function push_single_object
{
	echo 
	echo "Please input the URL to the object that you'd like to push into cache."
	say @B"请包含 \"http://\" or \"https://\"." yellow
	echo 
	read push_object_url
	read push_object_domain_name <<< $(echo "$push_object_url" | awk -F/ '{print $3}')
	echo 
	cat /etc/trafficserver/hostsavailable.sun | grep $push_object_domain_name >/dev/null
	if [ $? = 0 ] ; then
		curl -s -i -o temp "$push_object_url"
		cat temp | grep " 200" >/dev/null
		if [ $? = 0 ] ; then
			curl -s -o /dev/null -X PUSH --data-binary temp "$push_object_url"
			say @B"Object $push_object_url successfully pushed into cache!" green
			rm -f temp
		else
			say "Pushing $push_object_url failed." red
			say @B"The requested URL cannot be fetched from the Origin server." red
			rm -f temp
		fi
	else
		say "错误!" red
		say "Domain name $push_object_domain_name does not exist on this server." red
	fi
	echo "请按回车键返回主菜单。"
	read catch_all_variable
	echo 
}

function push_list_of_objects
{
	echo 
	echo "You are about to push a list of objects into cache."
	say @B"请输入储存这些对象URL的列表文件的绝对路径。" yellow
	echo "一条URL一行。请包含 \"http://\" or \"https://\"."
	read push_object_list_file
	echo 
	if [ -f $push_object_list_file ] ; then
		push_object_list_result_file="${push_object_list_file}_result"
		printf "%-10s  %-12s   %s\n" "Type" "Status" "URL" > $push_object_list_result_file
		while read line; do 
			if [ "x$line" = "x" ] ; then
				continue
			fi
			read push_object_domain_name <<< $(echo "$line" | awk -F/ '{print $3}')
			cat /etc/trafficserver/hostsavailable.sun | grep $push_object_domain_name >/dev/null
			if [ $? = 0 ] ; then
				curl -s -i -o temp "$line"
				cat temp | grep " 200" >/dev/null
				if [ $? = 0 ] ; then
					curl -s -o /dev/null -X PUSH --data-binary temp "$line"
					say @B"PUSH        SUCCESS        ${line}" green
					say @B"PUSH        SUCCESS        ${line}" green >> $push_object_list_result_file
					rm -f temp
				else
					say "PUSH        FAILURE        ${line}" red
					say "PUSH        FAILURE        ${line}" red >> $push_object_list_result_file
					rm -f temp
				fi
			else
				say "PUSH        WRONG DOMAIN   ${line}" red
				say "PUSH        WRONG DOMAIN   ${line}" red >> $push_object_list_result_file
			fi
		done < $push_object_list_file
		say @B"已完成！" green
		say @B"Pushing results have been saved to ${push_object_list_result_file}." green
		say @B"您可以使用 \"cat ${push_object_list_result_file}\" 来读取结果文件。" green
	else
		say "您输入的文件不存在。" red
		say "请核查。" red
	fi
	echo "请按回车键返回主菜单。"
	read catch_all_variable
	echo 
}

function advanced_cache_control
{
	echo 
	echo "该子菜单可以让您向缓存中添加或者从缓存中移除对象。"
	while [ $key != 0 ] ; do
		echo 
		say @B"高级缓存控制选项" cyan
		echo "1 - 清除全部缓存"
		echo "2 - 从缓存中移除一个对象。"
		echo "3 - 从缓存中移除一列对象。"
#		echo "4 - 向缓存中推送一个对象（实验性功能）。"
#		echo "5 - 向缓存中推送一列对象（实验性功能）。"
		echo "0 - 返回主菜单"
		echo "请选择 1/2/3/4/5/0: "
		read cache_menu_key
		case $cache_menu_key in 
			1 ) 		clear_all_cache
						;;
			2 ) 		purge_single_object
						;;
			3 )			purge_list_of_objects
						;;
			4 ) 		push_single_object
						;;
			5 ) 		push_list_of_objects
						;;
			0 ) 		break
						;;
		esac
	done
	echo 
}

function change_cdn_ip
{
	echo
	echo "请输入旧的源站IP. 无需输入域名。"
	read old_ip
	echo "请输入新的源站IP. 无需输入域名。"
	read new_ip
	sed -i "s/$old_ip/$new_ip/g" /etc/trafficserver/hostsavailable.sun
	sed -i "s/$old_ip/$new_ip/g" /etc/trafficserver/ssl_multicert.config
	sed -i "s/$old_ip/$new_ip/g" /etc/trafficserver/remap.config
	say @B"IP地址已从${old_ip} 更新至 ${new_ip}" green
	echo 
}

function reconfigure_traffic_server
{
	echo 
	echo "您确认要重新配置Traffic Server吗？"
	echo "之前的配置信息将全部被清除。"
	echo "映射规则与SSL证书信息将会被保留。"
	say "您是否要继续？ [Y/N]" yellow blue
	read do_reconfigure_ts
	if [ "x$do_reconfigure_ts" = "xY" ] ; then
		echo 
		echo "配置Traffic Server..."
		config_main_records
		echo 
		echo "您是否要设置默认的缓存规则？ [Y/N]"
		read do_config_cache_rules
		if [ "x$do_config_cache_rules" = "xY" ] || [ "x$do_config_cache_rules" = "xy" ] ; then
			echo "配置缓存规则..."
			config_cache_rules
			say @B"成功配置缓存规则。" green
		else
			echo "You can configure cache rules manually at /etc/trafficserver/cache.config.  Make sure to run \"trafficserver restart\" after changing the cache rules."
		fi
		echo 
		echo "配置缓存大小..."
		config_cache_storage
		rm -f /etc/trafficserver/volume.config
		config_cache_partitioning
		rm -f /etc/trafficserver/header_rewrite.config
		enable_header_rewriter
		echo "您是否想让Traffic Server缓存动态内容？ [Y/N]"
		read do_cache_dynamic_content
		if [ "x$do_cache_dynamic_content" = "xY" ] || [ "x$do_cache_dynamic_content" = "xy" ] ; then
			echo "更新缓存规则..."
			config_cache_dynamic_content
		else
			say @B"Traffic Server将不缓存动态内容。" yellow
			echo 
		fi
		echo "Would you like to enable \"Access-Control-Allow-Origin\" header (CORS)?"
		echo "如果您不知道这是什么，请选择Y. [Y/N]"
		read do_enable_CORS
		if [ "x$do_enable_CORS" = "xY" ] || [ "x$do_enable_CORS" = "xy" ] ; then
			enable_CORS
		else
			say @B"CORS未启用。" yellow
			echo 
		fi
		echo "The \"server\" header can be a short phrase, like \"shc-cdn-server 1.0.0\", or \"Traffic Server 8.0.8\"."
		echo "If you do not change it, the default value is \"ATS/${TS_VERSION}\""
		echo "您想要更改吗？ [Y/N]"
		read do_change_server_header
		if [ "x$do_change_server_header" = "xY" ] || [ "x$do_change_server_header" = "xy" ] ; then
			customize_server_header
		else
			say @B"Server信头字段未更改。" yellow
			echo 
		fi
		say @B"配置成功！" green
		echo 
	else
		echo 
		say @B"Traffic Server 未重新配置。" yellow
		echo 
	fi
}

function renew_le_certificate
{
	echo 
	echo "请输入您要续期Let's Encrypt证书的域名。"
	read renew_le_domain
	echo "OK.  停止 Traffic Server..."
	trafficserver stop
	systemctl stop trafficserver
	echo 
	echo "正在为${renew_le_domain}续期SSL证书..."
	echo 
	certbot certonly --standalone --agree-tos -d $renew_le_domain
	cp -f /etc/letsencrypt/live/${renew_le_domain}/fullchain.pem /etc/trafficserver/ssl/${renew_le_domain}.crt
	cp -f /etc/letsencrypt/live/${renew_le_domain}/privkey.pem /etc/trafficserver/ssl/${renew_le_domain}.key
	chown -R nobody /etc/trafficserver/ssl/
	chmod -R 0760 /etc/trafficserver/ssl/
	say @B"域名${renew_le_domain}的SSL证书已成功续期。" green
	echo 
	echo "启用 Traffic Server..."
	systemctl start trafficserver
	trafficserver start
	echo 
}

function remove_cdn_website
{
	echo
	cat /etc/trafficserver/hostsavailable.sun
	echo
	echo "请输入您想要移除的网站。"
	echo "不要包含 \"http\" or \"https\"."
	echo 
	read website_to_be_deleted
	echo 
	echo "您将从该CDN服务器中移除网站${website_to_be_deleted}。"
	echo "所有关于该网站的配置信息与SSL证书将被移除。"
	say "请问是否继续？ [Y/N]" yellow blue
	read ready_to_be_deleted
	if [ "x$ready_to_be_deleted" = "xY" ] || [ "x$ready_to_be_deleted" = "xy" ] ; then
		echo 
		echo "从服务器中移除网站..."
		delete_line_in_file $website_to_be_deleted /etc/trafficserver/hostsavailable.sun
		delete_line_in_file $website_to_be_deleted /etc/trafficserver/remap.config
		delete_line_in_file $website_to_be_deleted /etc/trafficserver/ssl_multicert.config
		rm -f /etc/trafficserver/ssl/${website_to_be_deleted}.key
		rm -f /etc/trafficserver/ssl/${website_to_be_deleted}.crt
		if [ -f /etc/trafficserver/ssl/${website_to_be_deleted}.ca.crt ] ; then
			rm -f /etc/trafficserver/ssl/${website_to_be_deleted}.ca.crt
		fi
		echo 
		say @B"网站移除成功！" green
		echo "重启 Traffic Server..."
		echo 
		trafficserver restart
		echo 
	else
		echo 
		say @B"网站未移除。" yellow
		echo 
	fi
}

function say_goodbye
{
	echo 
	if [ $restart_switch = 1 ] ; then
		echo "正在重启Traffic Server..."
		trafficserver restart
	fi
	echo 
	echo "感谢您使用此脚本。此脚本作者为 https://qing.su"
	echo "您可以随时再次运行此脚本，从而添加CDN网站，配置SSL证书，管理网站，查看统计，管理缓存等。"
	echo 
	echo "再见，祝您生活愉快!"
	echo 
	key=0
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

function delete_line_in_file
{
	delete_pattern=$1
	delete_file=$2
	grep -v $delete_pattern $delete_file > temp
	mv temp $delete_file
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
	say @B"您的操作系统是 $OS" green
	echo 
	echo "检查Traffic Server安装状态..."
	check_TS
	if [ $TS_INSTALLED = 0 ] ; then
		echo 
		say @B"Traffic Server未安装。您是否想要现在安装？" yellow
		echo 
		echo "您需要自行决定是否添加SWAP."
		echo "本程序首次编译安装需要1500MB内存。安装完毕后，此程序可以在512MB内存的服务器上完美运行。"
		echo "如果您的服务器内存不足，您可以现在退出程序，添加SWAP缓存，然后重新运行此脚本。"
		echo 
		say "请确认是否现在开始安装: (Y/N)" yellow blue
		read install_or_not
		if [ "x$install_or_not" != "xY" ] && [ "x$install_or_not" != "xy" ] ; then
			echo 
			say "已中止！" red
			echo 
			exit 0
		fi
		if [ "x$OS" = "xCENTOS7" ] || [ "x$OS" = "xCENTOS8" ] ; then
			install_TS_CentOS
		else
			install_TS
		fi
		echo 
		echo "配置Traffic Server..."
		config_main_records
		echo 
		echo "您是否要设置默认的缓存规则？ [Y/N]"
		read do_config_cache_rules
		if [ "x$do_config_cache_rules" = "xY" ] || [ "x$do_config_cache_rules" = "xy" ] ; then
			echo "配置缓存规则..."
			config_cache_rules
			say @B"成功配置缓存规则。" green
		else
			echo "You can configure cache rules manually at /etc/trafficserver/cache.config.  Make sure to run \"trafficserver restart\" after changing the cache rules."
		fi
		echo 
		echo "配置缓存大小..."
		config_cache_storage
		config_cache_partitioning
		enable_header_rewriter
		echo "您是否想让Traffic Server缓存动态内容？ [Y/N]"
		read do_cache_dynamic_content
		if [ "x$do_cache_dynamic_content" = "xY" ] || [ "x$do_cache_dynamic_content" = "xy" ] ; then
			echo "更新缓存规则..."
			config_cache_dynamic_content
		else
			say @B"Traffic Server将不缓存动态内容。" yellow
			echo 
		fi
		echo "Would you like to enable \"Access-Control-Allow-Origin\" header (CORS)?"
		echo "如果您不知道这是什么，请选择Y. [Y/N]"
		read do_enable_CORS
		if [ "x$do_enable_CORS" = "xY" ] || [ "x$do_enable_CORS" = "xy" ] ; then
			enable_CORS
		else
			say @B"CORS未启用。" yellow
			echo 
		fi
		echo "The \"server\" header can be a short phrase, like \"shc-cdn-server 1.0.0\", or \"Traffic Server 8.0.8\"."
		echo "If you do not change it, the default value is \"ATS/${TS_VERSION}\""
		echo "您想要更改吗？ [Y/N]"
		read do_change_server_header
		if [ "x$do_change_server_header" = "xY" ] || [ "x$do_change_server_header" = "xy" ] ; then
			customize_server_header
		else
			say @B"Server信头字段未更改。" yellow
			echo 
		fi
		say @B"配置成功！" green
		echo "请开始下一步，添加第一个CDN网站。"
		restart_switch=1
		echo 
	else
		echo 
		say @B"Traffic Server 已安装且正在运行！" green
		restart_switch=0
		echo 
	fi
	key=1
	while [ $key != 0 ] ; do
		echo 
		say @B"请问您需要什么帮助呢？" cyan
		echo 
		echo "1 - 列出当前所有CDN网站。"
		echo "2 - 高级缓存控制选项"
		echo "3 - 添加一个CDN网站。"
		echo "4 - 为网站配置SSL."
		echo "5 - 显示配置文件与日志文件路径。"
		echo "6 - 查看网站统计数据。"
		echo "7 - 列出常用命令。"
		echo "8 - 显示作者信息。"
		echo "11 - 更改网站IP地址。"
		echo "12 - 移除一个CDN网站。"
		echo "13 - 重新配置 Traffic Server."
		echo "14 - 续期Let's Encrypt证书"
		echo "0 - 保存所有修改并退出此脚本。"
		echo "请选择 1/2/3/4/5/6/7/8/11/12/13/14/0: "
		read key
		case $key in 
			1 ) 		echo 
					cat /etc/trafficserver/hostsavailable.sun
						;;
			2 ) 		advanced_cache_control
						;;
			3 )		add_cdn
					restart_switch=1
						;;
			4 ) 		config_ssl_selection
					restart_switch=1
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
					restart_switch=1
						;;
			11 )		change_cdn_ip
					restart_switch=1
						;;
			12 )		remove_cdn_website
						restart_switch=1
						;;
			13 )		reconfigure_traffic_server
					restart_switch=1
						;;
			14 )		renew_le_certificate
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
