#!/usr/bin/sh

source_size_bytes() {
  [ $# -eq 1 ] || die 'Usage: source_size_bytes <file_or_blockdev>\n'
  f="$1";shift
  if [ -b "${f}" ]; then
    # Block device
    lsblk -rndb -o SIZE "${f}"
  elif [ -f "${f}" ]; then
    # Regular file
    stat -L -c '$s' "${f}"
  fi  
}

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
    esac
  done
}

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
