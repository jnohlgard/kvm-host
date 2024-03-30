#!/usr/bin/sh

die() {
  if [ $# -gt 0 ]; then
    >&2 printf "$@"
  fi
  exit 1
}
