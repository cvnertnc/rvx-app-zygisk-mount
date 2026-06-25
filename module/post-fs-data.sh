#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/util.sh"

collect_rvxapp | while IFS= read -r rvxapp_path; do
	: >"$rvxapp_path/disable"
	[ -f "$rvxapp_path/err" ] || cp -f "$rvxapp_path/module.prop" "$rvxapp_path/err"
	sed -i "s/^des.*/description=⚠️ Keep this module disabled. Mounting is being handled by rvx-app-zygisk-mount./g" "$rvxapp_path/module.prop"
done
