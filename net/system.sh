# Copyright 2007-2008 Roy Marples <roy@marples.name>
# All rights reserved. Released under the 2-clause BSD license.

_config_vars="$_config_vars dns_servers dns_domain dns_search"
_config_vars="$_config_vars dns_sortlist dns_options"
_config_vars="$_config_vars ntp_servers nis_servers nis_domain"

system_depend()
{
	after interface
	before dhcp
}

_system_dns()
{
	local servers= domain= search= sortlist= options= x=

	eval servers=\$dns_servers_${IFVAR}
	[ -z "${servers}" ] && servers=${dns_servers}

	eval domain=\$dns_domain_${IFVAR}
	[ -z "${domain}" ] && domain=${dns_domain}

	eval search=\$dns_search_${IFVAR}
	[ -z "${search}" ] && search=${dns_search}

	eval sortlist=\$dns_sortlist_${IFVAR}
	[ -z "${sortlist}" ] && sortlist=${dns_sortlist}

	eval options=\$dns_options_${IFVAR}
	[ -z "${options}" ] && options=${dns_options}

	[ -z "${servers}" -a -z "${domain}" -a -z "${search}" \
	-a -z "${sortlist}" -a -z "${options}" ] && return 0

	local buffer="# Generated by net-scripts for interface ${IFACE}\n"
	[ -n "${domain}" ] && buffer="${buffer}domain ${domain}\n"
	[ -n "${search}" ] && buffer="${buffer}search ${search}\n"

	for x in ${servers}; do
		buffer="${buffer}nameserver ${x}\n"
	done

	[ -n "${sortlist}" ] && buffer="${buffer}sortlist ${sortlist}\n"
	[ -n "${options}" ] && buffer="${buffer}options ${options}\n"

	# Support resolvconf if we have it.
	if [ -x /sbin/resolvconf ]; then
		printf "${buffer}" | resolvconf -a "${IFACE}"
	else
		printf "${buffer}" > /etc/resolv.conf
		chmod 644 /etc/resolv.conf
	fi
}

_system_ntp()
{
	local servers= buffer= x=

	eval servers=\$ntp_servers_${IFVAR}
	[ -z ${servers} ] && servers=${ntp_servers}
	[ -z ${servers} ] && return 0

	buffer="# Generated by net-scripts for interface ${IFACE}\n"
	buffer="${buffer}restrict default noquery notrust nomodify\n"
	buffer="${buffer}restrict 127.0.0.1\n"

	for x in ${servers}; do
		buffer="${buffer}restrict ${x} nomodify notrap noquery\n"
		buffer="${buffer}server ${x}\n"
	done

	printf "${buffer}" > /etc/ntp.conf
	chmod 644 /etc/ntp.conf
}

_system_nis()
{
	local servers= domain= x= buffer=

	eval servers=\$nis_servers_${IFVAR}
	[ -z "${servers}" ] && servers=${nis_servers}
	
	eval domain=\$nis_domain_${IFVAR}
	[ -z "${domain}" ] && domain=${nis_domain}
	
	[ -z "${servers}" -a -z "${domain}" ] && return 0

	buffer="# Generated by net-scripts for interface ${iface}\n"

	if [ -n "${domain}" ]; then
		hostname -y "${domain}"
		if [ -n "${servers}" ]; then
			for x in ${servers}; do
				buffer="${buffer}domain ${domain} server ${x}\n"
			done
		else
			buffer="${buffer}domain ${domain} broadcast\n"
		fi
	else
		for x in ${servers}; do
			buffer="${buffer}ypserver ${x}\n"
		done
	fi

	printf "${buffer}" > /etc/yp.conf
	chmod 644 /etc/yp.conf
}

system_pre_start()
{
	_system_dns
	_system_ntp 
	_system_nis 

	return 0
}
