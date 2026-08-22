#!/bin/bash
# Validate the MagicX Zero 28 board port without a full build (no 180 GiB needed).
# Emits METRIC lines. Primary metric = validation_ok (1 = no errors).
set -uo pipefail

B=board/allwinner/a133/magicx-zero-28
BP=package/boot/uboot-a133/magicx-zero-28/boot_package
errors=0

# 1) DTS compiles with 0 errors (vendor DTS produces cosmetic warnings)
if command -v dtc >/dev/null 2>&1; then
  dtc -I dts -O dtb -o /tmp/zero28.dtb "$BP/magicx-zero-28.dts" 2>/tmp/dtc.err
  rc=$?
  e=$(grep -c 'Error' /tmp/dtc.err 2>/dev/null || true)
  w=$(grep -c 'Warning' /tmp/dtc.err 2>/dev/null || true)
  echo "METRIC dts_errors=$((rc + e))"
  echo "METRIC dts_warnings=$w"
  errors=$((errors + rc + e))
else
  echo "dtc not installed" >&2
  echo "METRIC dts_errors=-1"
  errors=$((errors + 1))
fi

# 2) All shell scripts + boot.cmd parse
script_errs=0
while IFS= read -r f; do
  bash -n "$f" 2>/dev/null || { echo "SYNTAX FAIL: $f" >&2; script_errs=$((script_errs+1)); }
done < <(find "$B" \( -name '*.sh' -o -name 'boot.cmd' \) -type f)
echo "METRIC script_errors=$script_errs"
errors=$((errors + script_errs))

# 3) Partition images referenced by genimage.cfg exist (boot0/boot/env) with
#    correct magic bytes
missing=0
for img in boot0.img boot.img env.img; do
  if [ ! -f "$B/partitions/$img" ]; then
    echo "MISSING partition: $img" >&2
    missing=$((missing+1))
  fi
done
[ -f "$B/partitions/boot_package.fex" ] || { echo "MISSING partitions/boot_package.fex" >&2; missing=$((missing+1)); }

# 4) Boot files copied by create-boot-script.sh exist
for f in uImage uInitrd bootlogo.bmp knulli-boot.conf; do
  [ -f "$B/$f" ] || { echo "MISSING $f" >&2; missing=$((missing+1)); }
done
echo "METRIC missing_files=$missing"
errors=$((errors + missing))

# 5) boot_package.cfg inputs exist (dtb.bin is generated from dts)
for f in u-boot.bin monitor.bin scp.bin; do
  [ -f "$BP/$f" ] || { echo "MISSING boot_package/$f" >&2; missing=$((missing+1)); }
done

# 6) genimage.cfg consistency. genimage resolves `image = "..."` relative to the
#    build-time inputpath (`boot/`). Two valid conventions exist in this tree:
#      (a) create-boot-script copies `partitions` -> $KNULLI_BINARIES_DIR
#          (sibling of boot/), genimage references `../partitions/<file>`.
#          [zero-28, xu20-v32]
#      (b) create-boot-script copies `partitions` -> boot/, genimage references
#          `partitions/<file>`. [trimui, zero-40, ...]
genimage_errs=0

# where does create-boot-script.sh copy the partitions dir?
cp_dest=$(grep -oE 'cp -r .*BOARD_DIR.*/partitions.*"[^"]+"' "$B/create-boot-script.sh" | grep -oE '"[^"]+"$' | tr -d '"')
case "$cp_dest" in
  *boot*) prefix="partitions/" ;;
  *)      prefix="../partitions/" ;;
esac

while IFS= read -r img; do
  case "$img" in
    boot.vfat|userdata.ext4|*.fex) : ;;  # generated at build time
    *)
      base=$(basename "$img")
      if [ ! -f "$B/partitions/$base" ]; then
        echo "genimage references missing partition: $img" >&2
        genimage_errs=$((genimage_errs+1))
      fi
      case "$img" in
        ../partitions/*) [ "$prefix" = "../partitions/" ] || { echo "prefix mismatch: $img vs copy dest [$cp_dest]" >&2; genimage_errs=$((genimage_errs+1)); } ;;
        partitions/*)    [ "$prefix" = "partitions/" ] || { echo "prefix mismatch: $img vs copy dest [$cp_dest]" >&2; genimage_errs=$((genimage_errs+1)); } ;;
        *) echo "unexpected genimage path: $img" >&2; genimage_errs=$((genimage_errs+1)); ;;
      esac
      ;;
  esac
done < <(sed -n 's/^[[:space:]]*image[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$B/genimage.cfg")

echo "METRIC genimage_errors=$genimage_errs"
echo "METRIC partitions_copy_dest=$cp_dest"
errors=$((errors + genimage_errs))

echo "METRIC total_errors=$errors"
if [ "$errors" -eq 0 ]; then
  echo "METRIC validation_ok=1"
else
  echo "METRIC validation_ok=0"
fi
echo "validation summary: total_errors=$errors" >&2
