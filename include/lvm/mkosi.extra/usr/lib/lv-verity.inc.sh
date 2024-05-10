#!/usr/bin/sh
set -euf

die() {
  if [ $# -gt 0 ]; then
    >&2 printf "$@"
  fi
  exit 1
}

# Get the apparent size of a file or block device
# NB: The actual space consumed by the file may be less than the apparent size
# because of sparse files and deduplicated extents, so `du` may not give the
# same result.
source_size_bytes() {
  [ $# -eq 1 ] || die 'Usage: source_size_bytes <file_or_blockdev>\n'
  f="$1";shift
  if [ -b "${f}" ]; then
    # Block device
    lsblk -rndb -o SIZE "${f}"
  elif [ -f "${f}" ]; then
    # Regular file
    stat -L -c '%s' "${f}"
  fi  
}

# Grab the value part of a kernel command line argument
# 1 is printed if the argument is provided without value (no "=" component)
kernel_cmdline_arg() {
  [ $# -eq 1 ] || die 'Usage: kernel_cmdline_arg <search>\n'

  argname="$1";shift
  set -- $(cat /proc/cmdline)
  for arg in "$@"; do
    case "${arg}" in
      "${argname}="*)
        printf '%s' "${arg#*=}"
        return
        ;;
      "${argname}")
        printf '1'
        return
        ;;
    esac
  done
}

# systemd-repart uses the leftmost 128 bits of the roothash for the partition
# UUID of the data partition and the rightmost 128 bits of the hash as the
# partition UUID of the hash partition
verity_hash_uuid_from_roothash() {
  [ $# -eq 1 ] || die 'Usage: verity_hash_uuid_from_roothash <roothash>\n'

  roothash="$1";shift
  printf '%s' "${roothash}" | \
    sed -E \
    -e 's/^.*([0-9a-f]{8})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{12})$/\1-\2-\3-\4-\5/'
}
verity_data_uuid_from_roothash() {
  [ $# -eq 1 ] || die 'Usage: verity_data_uuid_from_roothash <roothash>\n'

  roothash="$1";shift
  printf '%s' "${roothash}" | \
    sed -E \
    -e 's/^([0-9a-f]{8})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{12}).*$/\1-\2-\3-\4-\5/'
}

# Get all tags for the given LVs or all LVs
lv_tags() {
  /usr/sbin/lvm lvs \
    --ignorelockingfailure \
    --readonly \
    --config='global/wait_for_locks=0' \
    -o 'tags' \
    --reportformat=json_std \
    "$@" \
    | jq -r '.report[].lv[].lv_tags[]?'
}
