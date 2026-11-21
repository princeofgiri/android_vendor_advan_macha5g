#!/vendor/bin/sh

########################################################
### init.insmod.cfg format:                          ###
### -----------------------------------------------  ###
### [insmod|setprop|enable/moprobe] [path|prop name] ###
### ...                                              ###
########################################################

if [ $# -eq 1 ]; then
  cfg_file=$1
else
  exit 1
fi

if [ -f $cfg_file ]; then
  while IFS="|" read -r action arg
  do
    case $action in
      "insmod") insmod $arg ;;
      "setprop") setprop $arg 1 ;;
      "enable") echo 1 > $arg ;;
      "modprobe")
        modules_file="/vendor/lib/modules/modules.load"
        if [ ! -f "$modules_file" ]; then
          modules_file="/vendor_dlkm/lib/modules/modules.load"
        fi
        if [ -f "$modules_file" ]; then
          while read -r mod; do
            [ -z "$mod" ] && continue
            case "$mod" in \#*) continue ;; esac
            mod="${mod%$'\r'}"
            if [ -f "/vendor/lib/modules/$mod" ]; then
              echo "init.insmod: loading /vendor/lib/modules/$mod" > /dev/kmsg 2>/dev/null
              insmod "/vendor/lib/modules/$mod" 2>/dev/null || modprobe -d /vendor/lib/modules "$mod" 2>/dev/null
            elif [ -f "/vendor_dlkm/lib/modules/$mod" ]; then
              echo "init.insmod: loading /vendor_dlkm/lib/modules/$mod" > /dev/kmsg 2>/dev/null
              insmod "/vendor_dlkm/lib/modules/$mod" 2>/dev/null || modprobe -d /vendor_dlkm/lib/modules "$mod" 2>/dev/null
            else
              echo "init.insmod: modprobe $mod" > /dev/kmsg 2>/dev/null
              modprobe -d /vendor/lib/modules "$mod" 2>/dev/null
            fi
          done < "$modules_file"
        fi
        ;;
    esac
  done < $cfg_file
fi
