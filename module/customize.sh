#!/system/bin/sh

if [ -n "$KSU" ]; then
	ui_print "* KernelSU detected. Make sure you are using a Zygisk module!"
fi

. "$MODPATH/util.sh"

if [ -z "$(collect_rvx)" ]; then
	ui_print "* No rvx-app is installed."
	ui_print "  Go install the modules you want first,"
	ui_print "  then flash this module."
	abort ""
fi

chmod -R +x "$MODPATH/bin"
disable_unmount_modules
P=/data/adb/modules/rvx-zygisk-mount
if [ -d $P ]; then
	create_procs_map $P
fi

chmod +x "$MODPATH/service.sh"
REAPPLY=/data/data/com.termux/files/usr/bin/
if [ -d $REAPPLY ]; then
	echo "su -c 'MODDIR=$MODPATH /data/adb/modules/rvx-zygisk-mount/service.sh'; echo Done.;" >$REAPPLY/rvx-zygisk-mount
	chmod 777 $REAPPLY/rvx-zygisk-mount
fi

ui_print "* Done"
ui_print "  by j-hc (github.com/j-hc)"
ui_print "  rvx-app by cvnertnc (github.com/cvnertnc)"
