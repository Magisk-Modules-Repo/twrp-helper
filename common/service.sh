#!/system/bin/sh

to_hex() {
  echo -en "$1" | xxd -pc 256 | tr -d '[ \n]'
}

hexpatch() {
  local h_from=$(to_hex "$2")

  # If replacement string is shorter than original, pad it with spaces.
  #
  local rpadding=$(printf '%*s' $((${#2}-${#3})))
  local h_to=$(to_hex "$3$rpadding")

  echo -E "I${#2}: $2" >&2
  echo -E "O${#3}: $3" >&2
  echo I${#h_from}: $h_from >&2
  echo O${#h_to}: $h_to >&2

  [ ! -f $1 ] && abort 4 "File to be patched, $1, does not exist."

  # magiskboot exits with 0 whether it patches or not, so we capture its
  # output.
  #
  local output=$($mb hexpatch $1 $h_from $h_to 2>&1)
  count=$((count+1))

  if [ "${output/Patch/}" != "$output" ]; then
    echo $output >&2
    echo Patch $count succeeded. >&2
    return 0
  else
    abort $((128+$count)) "Patch $count failed."
  fi
}

abort() {
  echo "$2" >&2
  exit $1
}

# Uncomment this for extra logging.
#
# DEBUG=1
#
# Uncomment this to use a file instead of real recovery as the input image.
#
# RECOVERY_FILE=/storage/9C33-6BBD/twrp-beyond2lte-3.3.1-2_ianmacd-magisk.img
#
# Uncomment this to patch /dev/null instead of real recovery.
#
# DEVNULL=1

MODDIR=${0%/*}
# [ ! -d $MODDIR ] && MODDIR=/data/adb/modules/twrp-helper

# If the module is being uninstalled, then we need to reverse-patch and log
# outside the module's own directory, which will be removed.
#
if [ ${0##*/} = uninstall.sh ]; then
  set -- --reverse
  log=/data/adb/modules/twrp-helper.log
fi

mydir=${MODDIR:-/data/adb/modules/twrp-helper}
log=${log:-$mydir/twrp-helper.log}

# If in Magisk Manager, installation messages should go to the app's console.
# Otherwise, they should be logged unless stdout is a tty, which is the case
# if this script is being run from the command line. BOOTMODE is exported by
# installer.sh, so will be 'true' only if this script is called during
# installation from Magisk Manager.
#
if ([ ! -v BOOTMODE ] || [ "$BOOTMODE" = false ]) && [ ! -t 1 ]; then
  exec &> $log
fi

count=0
mb=/data/adb/magisk/magiskboot
recovery=$(readlink $(find /dev/block/platform -type l -iname recovery))
#recovery=/storage/9C33-6BBD/twrp-beyond2lte-3.3.1-2_ianmacd-magisk.img
store=/storage/emulated/0/Download
rd=ramdisk.cpio

if [ "$1" = --reverse ]; then
  new_twrp=twrp-unpatched.img
else
  new_twrp=twrp-patched.img
fi

if [ -v DEBUG ]; then
  echo "PWD     = $PWD" >&2
  echo "MODDIR  = $MODDIR" >&2
  echo "mydir   = $mydir" >&2
  echo "log     = $log\n" >&2
fi

cd $mydir || echo Failed to change from to $mydir. Continuing in $PWD... >&2

[ ! -b "$recovery" ] && abort 1 "Can't locate recovery block device."

trap 'rm -f recovery_dtbo kernel ramdisk.cpio strings twrp.img' EXIT

if [ -v RECOVERY_FILE ]; then
  recovery=$RECOVERY_FILE
fi
twrp=twrp.img
echo Reading recovery image from $recovery... >&2
cat $recovery > $twrp
rm -f $rd
$mb unpack $twrp

[ ! -f $rd ] && abort 2 'Failed to unpack ramdisk.'

cat <<'EOF' > strings
\x00/media\x00
\x00/.twrp\x00
Data (excl. storage)
Data (incl. storage)
Backups of {1} do not include any files in internal storage such as pictures or downloads.
Backups of {1} include files in internal storage such as pictures and downloads.
Wiping data without wiping /data/media ...
Wiping data and internal storage...
(not including internal storage)
(including internal storage)
EOF

IFS=$'\t\n'
exec < strings

while read -r from; do
  read -r to

  if [ "$1" = --reverse ]; then
    echo Operating in reverse mode... >&2
    hexpatch $rd $to $from
  else
    hexpatch $rd $from $to
  fi
  echo >&2
done

rm -f $new_twrp
$mb repack $twrp $new_twrp

[ ! -f $new_twrp ] && abort 3 'Failed to pack new ramdisk.'

if [ -v DEVNULL ]; then
  recovery=/dev/null
fi

echo Writing new recovery image to $recovery... >&2
dd if=$new_twrp of=$recovery bs=$(stat -c%s $new_twrp)

# Try to move the (un)patched TWRP image to the store directory, if mounted.
#
if [ -d $store ]; then
  echo Moving $new_twrp to $store... >&2
  mv $new_twrp $store
fi
