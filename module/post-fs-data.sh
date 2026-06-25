#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/util.sh"

collect_rvx | while IFS= read -r rvx_path; do
	: >"$rvx_path/disable"
	[ -f "$rvx_path/err" ] || cp -f "$rvx_path/module.prop" "$rvx_path/err"
	sed -i "s/^des.*/description=⚠️ Keep this module disabled. Mounting is being handled by rvx-zygisk-mount./g" "$rvx_path/module.prop"
done
