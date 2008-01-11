# Copyright 2007 Gentoo Foundation
# Copyright 2007-2008 Roy Marples <roy@marples.name>
# All rights reserved. Released under the 2-clause BSD license.

has_addon()
{
	[ -e "${RC_LIBDIR}/addons/$1.sh" ] || [ -e /lib/rcscripts/addons/"$1".sh ]
}

import_addon()
{
	if [ -e "${RC_LIBDIR}/addons/$1.sh" ]; then
		. "${RC_LIBDIR}/addons/$1.sh"
	elif [ -e /lib/rcscripts/addons/"$1".sh ]; then
		. /lib/rcscripts/addons/"$1".sh
	else
		return 1
	fi
}

start_addon()
{
	( import_addon "$1-start" )
}

stop_addon()
{
	( import_addon "$1-stop" )
}

net_fs_list="afs cifs coda davfs fuse gfs ncpfs nfs nfs4 ocfs2 shfs smbfs"
is_net_fs()
{
	[ -z "$1" ] && return 1

	# Check OS specific flags to see if we're local or net mounted
	mountinfo --quiet --netdev "$1"  && return 0
	mountinfo --quiet --nonetdev "$1" && return 1

	# Fall back on fs types
	local t=$(mountinfo --fstype "$1")
	for x in ${net_fs_list}; do
		[ "${x}" = "${t}" ] && return 0
	done
	return 1
}

is_union_fs()
{
	[ ! -x /sbin/unionctl ] && return 1
	unionctl "$1" --list >/dev/null 2>&1
}

get_bootparam()
{
	local match="$1"
	[ -z "${match}" -o ! -r /proc/cmdline ] && return 1

	set -- $(cat /proc/cmdline)
	while [ -n "$1" ]; do
		case "$1" in
			gentoo=*)
				local params="${1##*=}"
				local IFS=, x=
				for x in ${params}; do
					[ "${x}" = "${match}" ] && return 0
				done
				;;
		esac
		shift
	done

	return 1
}

# Add our sbin to $PATH
case "${PATH}" in
	/lib/rc/sbin|/lib/rc/sbin:*);;
	*) export PATH="/lib/rc/sbin:${PATH}";;
esac
