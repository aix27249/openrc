#!/bin/sh
# Copyright (c) 2007-2008 Roy Marples <roy@marples.name>
# Released under the 2-clause BSD license.

# Setup our resolv.conf
# Vitally important that we use the domain entry in resolv.conf so we
# can setup the nameservers are for the domain ONLY in resolvconf if
# we're using a decent dns cache/forwarder like dnsmasq and NOT nscd/libc.
# nscd/libc users will get the VPN nameservers before their other ones
# and will use the first one that responds - maybe the LAN ones?
# non resolvconf users just the the VPN resolv.conf

# FIXME:- if we have >1 domain, then we have to use search :/
# We need to add a flag to resolvconf to say
# "these nameservers should only be used for the listed search domains
#  if other global nameservers are present on other interfaces"
# This however, will break compatibility with Debians resolvconf
# A possible workaround would be to just list multiple domain lines
# and try and let resolvconf handle it

NS=
DOMAIN=
SEARCH=
i=1
while true; do
	eval opt=\$foreign_option_${i}
	[ -z "${opt}" ] && break
	if [ "${opt}" != "${opt#dhcp-option DOMAIN *}" ]; then
		if [ -z "${DOMAIN}" ]; then
			DOMAIN="${opt#dhcp-option DOMAIN *}"
		else
			SEARCH="${SEARCH:+ }${opt#dhcp-option DOMAIN *}"
		fi
	elif [ "${opt}" != "${opt#dhcp-option DNS *}" ]; then
		NS="${NS}nameserver ${opt#dhcp-option DNS *}\n"
	fi
	i=$((${i} + 1))
done

if [ -n "${NS}" ]; then
	DNS="# Generated by openvpn for interface ${dev}\n"
	if [ -n "${SEARCH}" ]; then
		DNS="${DNS}search ${DOMAIN} ${SEARCH}\n"
	else
		DNS="${DNS}domain ${DOMAIN}\n"
	fi
	DNS="${DNS}${NS}"
	if type resolvconf >/dev/null 2>&1; then
		printf "${DNS}" | resolvconf -a "${dev}"
	else
		# Preserve the existing resolv.conf
		if [ -e /etc/resolv.conf ]; then
			cp -p /etc/resolv.conf /etc/resolv.conf-"${dev}".sv
		fi
		(umask 022; printf "${DNS}" > /etc/resolv.conf)
	fi
fi

# Below section is OpenRC specific

# If we have a service specific script, run this now
[ -x "${RC_SVCNAME}"-up.sh ] && "${RC_SVCNAME}"-up.sh

# Re-enter the init script to start any dependant services
if [ -x "${RC_SERVICE}" ]; then
	if ! "${RC_SERVICE}" --quiet status; then
		export IN_BACKGROUND=true
		"${RC_SERVICE}" --quiet start
	fi
fi

exit 0
