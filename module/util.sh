#!/system/bin/sh

is_valid_rvx() {
	if [ ! -d "$1" ]; then return 1; fi
	if ! grep -Fq "j-hc" "$1/module.prop"; then return 1; fi
	if [ ! -f "$1/config" ]; then return 1; fi
	return 0
}

collect_rvx() {
	for RVX in /data/adb/modules_update/*-cvnertnc*; do
		if ! is_valid_rvx "$RVX"; then continue; fi

		MPATH=$(echo "$RVX" | sed 's/modules_update/modules/')
		if [ -f "$MPATH/remove" ]; then continue; fi

		echo "$RVX"
	done

	for RVX in /data/adb/modules/*-cvnertnc*; do
		if ! is_valid_rvx "$RVX"; then continue; fi
		if [ -f "$MPATH/remove" ]; then continue; fi

		MUPATH=$(echo "$RVX" | sed 's/modules/modules_update/')
		if [ -d "$MUPATH" ]; then continue; fi

		echo "$RVX"
	done
}

create_procs_map() {
	: >"$1/procs_map"
	collect_rvx | while IFS= read -r rvx_path; do
		. "$rvx_path/config"
		if [ -z "$PKG_NAME" ]; then continue; fi

		grep -F "$PKG_NAME" /proc/mounts | while read -r line; do
			mp=${line#* } mp=${mp%% *} mp=${mp%%\\*}
			ui_print "* Unmount '$mp'"
			umount -l "$mp"
		done
		am force-stop "$PKG_NAME"

		if ! BASEPATH=$(pm path "$PKG_NAME" 2>&1 </dev/null) || [ -z "$BASEPATH" ]; then
			ui_print "ERROR: $PKG_NAME is not installed. Re-flash its module and dont reboot."
			continue
		fi
		RVPATH="/data/adb/rvhc/${rvx_path##*/}.apk"
		if [ ! -f "$RVPATH" ]; then
			ui_print "ERROR: $RVPATH does not exist. Re-flash its module and dont reboot."
			continue
		fi

		for s in "$PKG_NAME" "$RVPATH" "${BASEPATH##*:}"; do
			printf '%b%s\0' "\\x$(printf '%02x' "${#s}")" "$s" >>"$1/procs_map"
		done

		ui_print "* Applied for $PKG_NAME"
	done
	printf '\0' >>"$1/procs_map"
}

disable_unmount_modules() {
	if magisk --denylist status >/dev/null 2>&1; then MGSK="mgsk"; fi

	collect_rvx | while IFS= read -r rvx_path; do
		. "$rvx_path/config"
		if [ -z "$PKG_NAME" ]; then continue; fi

		if [ "$KSU" ]; then
			uid=$(dumpsys package "$PKG_NAME" 2>&1 | grep -m1 "uid")
			uid=${uid#*=} uid=${uid%% *}
			if [ -z "$uid" ]; then
				uid=$(dumpsys package "$PKG_NAME" 2>&1 | grep -m1 userId)
				uid=${uid#*=} uid=${uid%% *}
			fi
			if [ -z "$uid" ]; then
				ui_print "* UID could not be found for $PKG_NAME"
				return 1
			fi

			if ! OP=$("${MODPATH:?}/bin/$ARCH/ksu_profile" "$uid" "$PKG_NAME" 2>&1); then
				ui_print "ERROR ksu_profile: $OP"
			fi
		elif [ "$MGSK" ]; then
			magisk --denylist rm "$PKG_NAME" || :
		fi
	done
	return 0
}
